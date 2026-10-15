const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// Load project settings even when the server is started with `node server.js`.
// Node 22 provides this API; preserve environment variables already set by shell.
if (typeof process.loadEnvFile === 'function') {
    try {
        process.loadEnvFile(path.join(__dirname, '.env'));
    } catch (error) {
        if (error.code !== 'ENOENT') throw error;
    }
}

const userModel = require('./models/user');
const menuModel = require('./models/menu');
const tableModel = require('./models/table');
const orderModel = require('./models/order');
const orderDetailModel = require('./models/order_detail');
const reservationModel = require('./models/reservation');
const paymentModel = require('./models/payment');
const { issueToken, requireAuth, requireAdmin } = require('./libs/auth_token');
const { notifyUser, startReservationReminderWorker } = require('./libs/notifications');
const { makePromptPayPayload } = require('./libs/promptpay');
const { validateSlot, bangkokDateTime } = require('./libs/booking_rules');
const { validMenuOptionGroups, resolveMenuSelections } = require('./libs/menu_options');
const pool = require('./libs/db_pool');

function normalizeThaiPhone(value) {
    if (typeof value !== 'string') return null;
    const trimmed = value.trim();
    const digits = trimmed.replace(/\D/g, '');
    if (/^0\d{9}$/.test(digits)) return `+66${digits.slice(1)}`;
    if (/^\+?66\d{9}$/.test(trimmed.replace(/[\s()-]/g, ''))) {
        return `+66${digits.slice(-9)}`;
    }
    return null;
}

function validEmail(value) {
    return value == null || value === '' || (typeof value === 'string' && value.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value));
}

const requireActiveUser = async (req, res, next) => {
    if (!req.authUser?.account_active || req.authUser.account_deleted) {
        return res.status(403).json({ isError: true, message: 'บัญชีนี้ถูกระงับการใช้งาน' });
    }
    next();
};

async function isCurrentAdmin(userId) {
    const account = await userModel.getUserById(userId);
    return Boolean(account && Number(account.role_id) === 1 && Number(account.is_active) === 1 && Number(account.is_deleted) !== 1);
}

const app = express();

const PORT = Number(process.env.PORT || 3000);

const restaurantBannerDirectory = path.join(__dirname, 'storage', 'restaurant_banner');
const restaurantBannerConfig = path.join(restaurantBannerDirectory, 'banner.json');
const restaurantBannerFilenamePattern = /^restaurant-banner-[a-f0-9-]+\.(png|jpe?g|webp)$/i;
const paymentSettingsDirectory = path.join(__dirname, 'storage', 'payment_settings');
const paymentSettingsConfig = path.join(paymentSettingsDirectory, 'settings.json');

function currentPaymentSettings() {
    try {
        const settings = JSON.parse(fs.readFileSync(paymentSettingsConfig, 'utf8'));
        return settings && typeof settings === 'object' ? settings : {};
    } catch (_) {
        return {};
    }
}

function normalizePromptPayId(value) {
    return typeof value === 'string' ? value.replace(/[\s-]/g, '') : '';
}

function currentPromptPayId() {
    const configuredId = normalizePromptPayId(currentPaymentSettings().promptpay_id);
    if (/^(0\d{9}|\d{13})$/.test(configuredId)) return configuredId;
    return normalizePromptPayId(process.env.PROMPTPAY_ID);
}

function savePaymentSettings(settings) {
    fs.mkdirSync(paymentSettingsDirectory, { recursive: true });
    const tempConfig = `${paymentSettingsConfig}.${crypto.randomUUID()}.tmp`;
    fs.writeFileSync(tempConfig, JSON.stringify(settings), { flag: 'wx' });
    fs.renameSync(tempConfig, paymentSettingsConfig);
}

function currentRestaurantBannerSettings() {
    try {
        const settings = JSON.parse(fs.readFileSync(restaurantBannerConfig, 'utf8'));
        return settings && typeof settings === 'object' ? settings : {};
    } catch (_) {
        return {};
    }
}

function currentRestaurantBannerFilename() {
    const filename = currentRestaurantBannerSettings().banner_image;
    return typeof filename === 'string' && restaurantBannerFilenamePattern.test(filename) ? filename : null;
}

function currentRestaurantBannerTitle() {
    const title = currentRestaurantBannerSettings().banner_title;
    return typeof title === 'string' && title.trim() ? title.trim() : 'ร้านอาหาร';
}

function saveRestaurantBannerSettings(settings) {
    fs.mkdirSync(restaurantBannerDirectory, { recursive: true });
    const tempConfig = `${restaurantBannerConfig}.${crypto.randomUUID()}.tmp`;
    fs.writeFileSync(tempConfig, JSON.stringify(settings), { flag: 'wx' });
    fs.renameSync(tempConfig, restaurantBannerConfig);
}

app.use(cors());

// Payment slips are sent as base64 JSON (up to 5 MB decoded), so the default
// Express 100 KB JSON limit rejects every normal slip upload.
app.use(express.json({ limit: '8mb' }));

app.get('/', (req, res) => {

    res.json({
        isError: false,
        message: 'Server is running'
    });

});

app.get('/api/users', requireAdmin, async (req, res) => {

    try {

        const result = await userModel.getAllUsers();

        res.json(result);

    } catch (error) {

        console.error('Get users error:', error);

        res.status(500).json({
            isError: true,
            data: [],
            errorMessage: error.message
        });

    }

});

app.post('/api/login', async (req, res) => {

    try {

        const {
            username,
            password
        } = req.body || {};

        if (typeof username !== 'string' || !username.trim() || typeof password !== 'string' || !password) {

            return res.status(400).json({
                isError: true,
                message: 'กรุณากรอก username และ password'
            });

        }

        const user =
            await userModel.getUserByUsername(username.trim());

        if (!user) {

            return res.status(401).json({
                isError: true,
                message: 'Username หรือ Password ไม่ถูกต้อง'
            });

        }

        if (Number(user.is_active) === 0 || Number(user.is_deleted) === 1) {
            return res.status(403).json({ isError: true, message: 'บัญชีนี้ถูกระงับการใช้งาน กรุณาติดต่อร้าน' });
        }

        const passwordMatch =
            await bcrypt.compare(
                password,
                user.password
            );

        if (!passwordMatch) {

            return res.status(401).json({
                isError: true,
                message: 'Username หรือ Password ไม่ถูกต้อง'
            });

        }

        return res.json({

            isError: false,

            message: 'Login success',

            data: {

                user_id: user.user_id,

                username: user.username,

                fullname: user.fullname,

                phone: user.phone,

                email: user.email,

                role_id: user.role_id,

                user_image: user.user_image,

                is_active: user.is_active,


                token: issueToken(user)

            }

        });

    } catch (error) {

        console.error('Login error:', error);

        return res.status(500).json({

            isError: true,

            message: 'เกิดข้อผิดพลาดของ Server'

        });

    }

});

app.post('/api/register', async (req, res) => {

    try {

        const {
            username,
            password,
            fullname,
            phone,
            email
        } = req.body || {};

        if (typeof username !== 'string' || typeof password !== 'string' ||
            typeof fullname !== 'string' || typeof phone !== 'string' ||
            !username.trim() || !password || !fullname.trim() || !phone.trim()) {

            return res.status(400).json({

                isError: true,

                message: 'กรุณากรอกชื่อผู้ใช้ รหัสผ่าน ชื่อ และเบอร์โทร'

            });

        }

        const cleanUsername = username.trim();
        const cleanFullname = fullname.trim();
        const cleanEmail = typeof email === 'string' ? email.trim() : '';
        const normalizedPhone = normalizeThaiPhone(phone);
        if (!/^[A-Za-z0-9_.-]{3,50}$/.test(cleanUsername)) {
            return res.status(400).json({ isError: true, message: 'Username ต้องมี 3–50 ตัว และใช้ได้เฉพาะตัวอักษรอังกฤษ ตัวเลข . _ -' });
        }
        if (Buffer.byteLength(password, 'utf8') < 8 || Buffer.byteLength(password, 'utf8') > 72) {
            return res.status(400).json({ isError: true, message: 'รหัสผ่านต้องมีความยาวอย่างน้อย 8 และไม่เกิน 72 ไบต์' });
        }
        if (cleanFullname.length > 150 || !normalizedPhone || !validEmail(cleanEmail)) {
            return res.status(400).json({ isError: true, message: 'กรุณาตรวจสอบชื่อ เบอร์โทรศัพท์ และอีเมล' });
        }
        const existingUser =
            await userModel.getUserByUsername(cleanUsername);

        if (existingUser) {

            return res.status(409).json({

                isError: true,

                message: 'Username นี้มีผู้ใช้งานแล้ว'

            });

        }

        const existingPhone = await userModel.getUserByPhone(normalizedPhone);
        if (existingPhone) {
            return res.status(409).json({ isError: true, message: 'เบอร์โทรนี้มีบัญชีผู้ใช้แล้ว' });
        }

        const hashedPassword =
            await bcrypt.hash(password, 10);

        const result =
            await userModel.createUser({

                username: cleanUsername,

                password: hashedPassword,

                fullname: cleanFullname,

                phone: normalizedPhone,

                email: cleanEmail || null,

                role_id: 2,

                user_image: null

            });

        return res.status(201).json({

            isError: false,

            message: 'Register success',

            data: {

                user_id: result.user_id,

                username: cleanUsername,

                fullname: cleanFullname,

                phone: normalizedPhone,

                email: cleanEmail || null,

                role_id: 2,

                is_active: 1,

                token: issueToken({ user_id: result.user_id, role_id: 2 })

            }

        });

    } catch (error) {

        console.error('Register error:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ isError: true, message: 'Username หรือเบอร์โทรนี้มีผู้ใช้งานแล้ว' });
        }

        return res.status(500).json({

            isError: true,

            message: 'เกิดข้อผิดพลาดของ Server'

        });

    }

});

app.put('/api/users/:id', requireAuth, requireActiveUser, async (req, res) => {

    try {

        const userId = Number(req.params.id);

        const {
            username,
            fullname,
            phone,
            email
        } = req.body;

        if (!Number.isInteger(userId) || userId <= 0) {

            return res.status(400).json({
                isError: true,
                message: 'user_id ไม่ถูกต้อง'
            });

        }

        if (Number(req.authUser.sub) !== userId && !(await isCurrentAdmin(req.authUser.sub))) {
            return res.status(403).json({ isError: true, message: 'ไม่มีสิทธิ์แก้ไขโปรไฟล์นี้' });
        }

        if (typeof fullname !== 'string' || !fullname.trim() || fullname.trim().length > 150) {

            return res.status(400).json({
                isError: true,
                message: 'กรุณากรอกชื่อ'
            });

        }

        const cleanUsername = typeof username === 'string' ? username.trim() : '';
        if (!/^[A-Za-z0-9_.-]{3,50}$/.test(cleanUsername)) {
            return res.status(400).json({ isError: true, message: 'ชื่อผู้ใช้ต้องยาว 3–50 ตัว และใช้ได้เฉพาะ a-z, 0-9, _, ., -' });
        }

        const existingUser =
            await userModel.getUserById(userId);

        if (!existingUser) {

            return res.status(404).json({
                isError: true,
                message: 'ไม่พบผู้ใช้งาน'
            });

        }

        const usernameOwner = await userModel.getUserByUsername(cleanUsername);
        if (usernameOwner && Number(usernameOwner.user_id) !== userId) {
            return res.status(409).json({ isError: true, message: 'ชื่อผู้ใช้นี้ถูกใช้แล้ว' });
        }

        const cleanPhone = typeof phone === 'string' ? phone.trim() : '';
        const normalizedPhone = cleanPhone ? normalizeThaiPhone(cleanPhone) : null;
        const cleanEmail = typeof email === 'string' ? email.trim() : '';
        if ((cleanPhone && !normalizedPhone) || !validEmail(cleanEmail)) {
            return res.status(400).json({ isError: true, message: 'กรุณาตรวจสอบรูปแบบเบอร์โทรศัพท์และอีเมล' });
        }
        if (normalizedPhone) {
            const duplicatePhone = await userModel.getUserByPhone(normalizedPhone);
            if (duplicatePhone && Number(duplicatePhone.user_id) !== userId) {
                return res.status(409).json({ isError: true, message: 'เบอร์โทรนี้มีบัญชีผู้ใช้อื่นแล้ว' });
            }
        }

        await userModel.updateUser(
            userId,
            {
                username: cleanUsername,
                fullname: fullname.trim(),
                phone: normalizedPhone,
                email: cleanEmail || null
            }
        );

        const updatedUser =
            await userModel.getUserById(userId);

        return res.json({

            isError: false,

            message: 'Update success',

            data: updatedUser

        });

    } catch (error) {

        console.error(
            'Update user error:',
            error
        );

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ isError: true, message: 'ชื่อผู้ใช้หรือเบอร์โทรนี้มีบัญชีอื่นแล้ว' });
        }

        return res.status(500).json({

            isError: true,

            message: 'เกิดข้อผิดพลาดของ Server'

        });

    }

});

app.put('/api/users/:id/profile-image', requireAuth, requireActiveUser, async (req, res) => {
    let savedFile;
    let persisted = false;
    try {
        const userId = Number(req.params.id);
        if (!Number.isInteger(userId) || userId < 1) return res.status(400).json({ isError: true, message: 'user_id ไม่ถูกต้อง' });
        if (Number(req.authUser.sub) !== userId && !(await isCurrentAdmin(req.authUser.sub))) return res.status(403).json({ isError: true, message: 'ไม่มีสิทธิ์แก้ไขรูปโปรไฟล์นี้' });
        const match = String(req.body?.image_data || '').match(/^data:image\/(png|jpeg|jpg);base64,([A-Za-z0-9+/=\r\n]+)$/i);
        if (!match) return res.status(400).json({ isError: true, message: 'เลือกรูป PNG หรือ JPEG' });
        const buffer = Buffer.from(match[2].replace(/\s/g, ''), 'base64');
        if (!buffer.length || buffer.length > 3 * 1024 * 1024) return res.status(400).json({ isError: true, message: 'รูปโปรไฟล์ต้องมีขนาดไม่เกิน 3 MB' });
        const isPng = buffer.length >= 8 && buffer.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
        const isJpeg = buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
        if (!isPng && !isJpeg) return res.status(400).json({ isError: true, message: 'ไฟล์นี้ไม่ใช่รูป PNG หรือ JPEG ที่ถูกต้อง' });
        const user = await userModel.getUserById(userId);
        if (!user) return res.status(404).json({ isError: true, message: 'ไม่พบผู้ใช้งาน' });
        const extension = match[1].toLowerCase() === 'png' ? 'png' : 'jpg';
        const fileName = `user-${userId}-${crypto.randomUUID()}.${extension}`;
        const folder = path.join(__dirname, 'storage', 'profile_images');
        fs.mkdirSync(folder, { recursive: true });
        savedFile = path.join(folder, fileName);
        fs.writeFileSync(savedFile, buffer, { flag: 'wx' });
        const updated = await userModel.updateProfileImage(userId, fileName);
        if (!updated) throw new Error('บันทึกรูปโปรไฟล์ไม่สำเร็จ');
        persisted = true;
        if (user.user_image && user.user_image !== fileName) {
            const previousFile = path.join(folder, path.basename(String(user.user_image)));
            if (previousFile !== savedFile && fs.existsSync(previousFile)) fs.unlinkSync(previousFile);
        }
        return res.json({ isError: false, message: 'เปลี่ยนรูปโปรไฟล์แล้ว', data: await userModel.getUserById(userId) });
    } catch (error) {
        if (!persisted && savedFile && fs.existsSync(savedFile)) {
            try { fs.unlinkSync(savedFile); } catch (_) { /* best-effort cleanup */ }
        }
        console.error('Update profile image error:', error);
        return res.status(500).json({ isError: true, message: 'เปลี่ยนรูปโปรไฟล์ไม่สำเร็จ' });
    }
});

app.get('/api/users/:id/profile-image', requireAuth, async (req, res) => {
    try {
        const userId = Number(req.params.id);
        if (!Number.isInteger(userId) || userId < 1) return res.status(400).json({ isError: true, message: 'user_id ไม่ถูกต้อง' });
        if (Number(req.authUser.sub) !== userId && !(await isCurrentAdmin(req.authUser.sub))) return res.status(403).json({ isError: true, message: 'ไม่มีสิทธิ์ดูรูปโปรไฟล์นี้' });
        const user = await userModel.getUserById(userId);
        if (!user?.user_image) return res.status(404).end();
        const file = path.join(__dirname, 'storage', 'profile_images', path.basename(String(user.user_image)));
        if (!fs.existsSync(file)) return res.status(404).end();
        res.setHeader('Cache-Control', 'private, max-age=3600');
        return res.sendFile(file);
    } catch (error) {
        console.error('Get profile image error:', error);
        return res.status(500).end();
    }
});

app.get('/api/menu', async (req, res) => {

    try {

        const result = await menuModel.getAllMenu({ availableOnly: true });

        return res.json(result);

    } catch (error) {

        console.error('Get menu error:', error);

        return res.status(500).json({

            isError: true,

            data: [],

            errorMessage: error.message

        });

    }

});

app.get('/api/menu/:id/image', async (req, res) => {
    try {
        const menu = (await menuModel.getAllMenu()).data.find((row) => Number(row.menu_id) === Number(req.params.id));
        if (!menu?.menu_image || !/^menu-[a-f0-9-]+\.(png|jpe?g|webp)$/i.test(menu.menu_image)) return res.status(404).end();
        const filePath = path.join(__dirname, 'storage', 'menu_images', path.basename(menu.menu_image));
        if (!fs.existsSync(filePath)) return res.status(404).end();
        return res.sendFile(filePath);
    } catch (error) { return res.status(500).end(); }
});

app.get('/api/restaurant/banner', (_req, res) => {
    return res.json({ isError: false, data: { banner_image: currentRestaurantBannerFilename(), banner_title: currentRestaurantBannerTitle() } });
});

app.get('/api/restaurant/banner/image', (_req, res) => {
    const filename = currentRestaurantBannerFilename();
    if (!filename) return res.status(404).end();
    const filePath = path.join(restaurantBannerDirectory, path.basename(filename));
    if (!fs.existsSync(filePath)) return res.status(404).end();
    return res.sendFile(filePath);
});

app.get('/api/admin/restaurant/banner', requireAdmin, (_req, res) => {
    return res.json({ isError: false, data: { banner_image: currentRestaurantBannerFilename(), banner_title: currentRestaurantBannerTitle() } });
});

app.get('/api/admin/payment-settings/promptpay', requireAdmin, (_req, res) => {
    return res.json({ isError: false, data: { promptpay_id: currentPromptPayId() } });
});

app.put('/api/admin/payment-settings/promptpay', requireAdmin, (req, res) => {
    const promptPayId = normalizePromptPayId(req.body?.promptpay_id);
    if (!/^(0\d{9}|\d{13})$/.test(promptPayId)) {
        return res.status(400).json({ isError: true, message: 'กรอกเบอร์ PromptPay 10 หลักที่ขึ้นต้นด้วย 0 หรือเลขประจำตัว 13 หลัก' });
    }
    try {
        const settings = currentPaymentSettings();
        settings.promptpay_id = promptPayId;
        savePaymentSettings(settings);
        return res.json({ isError: false, data: { promptpay_id: promptPayId } });
    } catch (error) {
        console.error('Save PromptPay settings error:', error.message);
        return res.status(500).json({ isError: true, message: 'บันทึกบัญชี PromptPay ไม่สำเร็จ' });
    }
});

app.put('/api/admin/restaurant/banner/title', requireAdmin, (req, res) => {
    const title = req.body?.banner_title;
    if (typeof title !== 'string' || !title.trim() || title.trim().length > 50) {
        return res.status(400).json({ isError: true, message: 'ชื่อบนภาพต้องมีความยาว 1–50 ตัวอักษร' });
    }
    try {
        const settings = currentRestaurantBannerSettings();
        settings.banner_title = title.trim();
        saveRestaurantBannerSettings(settings);
        return res.json({ isError: false, data: { banner_title: settings.banner_title } });
    } catch (error) {
        console.error('Save restaurant banner title error:', error.message);
        return res.status(500).json({ isError: true, message: 'บันทึกชื่อบนภาพไม่สำเร็จ' });
    }
});

app.post('/api/admin/restaurant/banner', requireAdmin, (req, res) => {
    try {
        const match = typeof req.body?.image_data === 'string' && req.body.image_data.match(/^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/=]+)$/);
        if (!match) return res.status(400).json({ isError: true, message: 'รูปภาพต้องเป็น PNG, JPEG หรือ WEBP' });
        const bytes = Buffer.from(match[2], 'base64');
        if (!bytes.length || bytes.length > 5 * 1024 * 1024) return res.status(400).json({ isError: true, message: 'รูปภาพต้องมีขนาดไม่เกิน 5 MB' });
        const extension = { png: 'png', jpeg: 'jpg', webp: 'webp' }[match[1]];
        const valid = extension === 'png'
            ? bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))
            : extension === 'jpg'
                ? bytes[0] === 0xff && bytes[1] === 0xd8 && bytes.at(-2) === 0xff && bytes.at(-1) === 0xd9
                : bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP';
        if (!valid) return res.status(400).json({ isError: true, message: 'ไฟล์รูปภาพไม่ถูกต้อง' });

        const previousFilename = currentRestaurantBannerFilename();
        fs.mkdirSync(restaurantBannerDirectory, { recursive: true });
        const filename = `restaurant-banner-${crypto.randomUUID()}.${extension}`;
        fs.writeFileSync(path.join(restaurantBannerDirectory, filename), bytes, { flag: 'wx' });
        const settings = currentRestaurantBannerSettings();
        settings.banner_image = filename;
        saveRestaurantBannerSettings(settings);

        if (previousFilename && previousFilename !== filename) {
            try { fs.unlinkSync(path.join(restaurantBannerDirectory, path.basename(previousFilename))); } catch (_) { /* best-effort cleanup */ }
        }
        return res.status(201).json({ isError: false, data: { banner_image: filename } });
    } catch (error) {
        console.error('Save restaurant banner error:', error.message);
        return res.status(500).json({ isError: true, message: 'บันทึกรูปหน้าร้านไม่สำเร็จ' });
    }
});

app.post('/api/admin/menu-image', requireAdmin, async (req, res) => {
    try {
        const match = typeof req.body?.image_data === 'string' && req.body.image_data.match(/^data:image\/(png|jpeg|webp);base64,([A-Za-z0-9+/=]+)$/);
        if (!match) return res.status(400).json({ isError: true, message: 'รูปภาพต้องเป็น PNG, JPEG หรือ WEBP' });
        const bytes = Buffer.from(match[2], 'base64');
        if (!bytes.length || bytes.length > 3 * 1024 * 1024) return res.status(400).json({ isError: true, message: 'รูปภาพต้องมีขนาดไม่เกิน 3 MB' });
        const ext = { png: 'png', jpeg: 'jpg', webp: 'webp' }[match[1]];
        const valid = ext === 'png' ? bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10])) : ext === 'jpg' ? bytes[0] === 0xff && bytes[1] === 0xd8 && bytes.at(-2) === 0xff && bytes.at(-1) === 0xd9 : bytes.subarray(0, 4).toString() === 'RIFF' && bytes.subarray(8, 12).toString() === 'WEBP';
        if (!valid) return res.status(400).json({ isError: true, message: 'ไฟล์รูปภาพไม่ถูกต้อง' });
        const filename = `menu-${crypto.randomUUID()}.${ext}`;
        const directory = path.join(__dirname, 'storage', 'menu_images');
        fs.mkdirSync(directory, { recursive: true });
        fs.writeFileSync(path.join(directory, filename), bytes, { flag: 'wx' });
        return res.status(201).json({ isError: false, data: { menu_image: filename } });
    } catch (error) { return res.status(500).json({ isError: true, message: 'บันทึกรูปเมนูไม่สำเร็จ' }); }
});

app.get('/api/tables', async (req, res) => {

    try {

        const result =
            await tableModel.getAllTables();

        return res.json(result);

    } catch (error) {

        console.error(
            'Get tables error:',
            error
        );

        return res.status(500).json({

            isError: true,

            data: [],

            errorMessage: error.message

        });

    }

});

app.get('/api/walk-in/tables', requireAuth, requireActiveUser, async (req, res) => {
    try {
        const data = await tableModel.getWalkInTables(req.authUser.sub);
        return res.json({ isError: false, data });
    } catch (error) {
        console.error('Get walk-in tables error:', error);
        return res.status(500).json({ isError: true, data: [], message: 'โหลดโต๊ะว่างไม่สำเร็จ' });
    }
});

app.get('/api/menu/:id', async (req, res) => {

    try {

        const menuId = Number(req.params.id);

        if (!Number.isInteger(menuId) || menuId <= 0) {

            return res.status(400).json({

                isError: true,

                data: null,

                errorMessage: 'menu_id ไม่ถูกต้อง'

            });

        }

        const menu =
            await menuModel.getMenuById(menuId);

        if (!menu) {

            return res.status(404).json({

                isError: true,

                data: null,

                errorMessage: 'ไม่พบเมนูที่ต้องการ'

            });

        }

        return res.json({

            isError: false,

            data: menu,

            errorMessage: ""

        });

    } catch (error) {

        console.error('Get menu by id error:', error);

        return res.status(500).json({

            isError: true,

            data: null,

            errorMessage: error.message

        });

    }

});

app.post('/api/orders', requireAuth, requireActiveUser, async (req, res) => {

    try {

        const { reservation_id, table_id } = req.body || {};

        const user_id = req.authUser.sub;
        if (reservation_id) {
            const reservation = await reservationModel.getReservationById(Number(reservation_id));
            if (!reservation || Number(reservation.user_id) !== Number(user_id)) {
                return res.status(403).json({ isError: true, message: 'ไม่พบการจองของบัญชีนี้' });
            }
        }

        const result =
            await orderModel.createOrder({

                user_id: user_id,

                reservation_id:
                    reservation_id || null,

                table_id: table_id || null

            });

        try {
            await notifyUser(user_id, {
                type: 'order_status',
                title: 'ส่งออร์เดอร์แล้ว',
                body: `ส่งออร์เดอร์ #${result.order_id} แล้ว กำลังรอร้านรับออร์เดอร์`,
                relatedId: result.order_id
            });
        } catch (notificationError) {
            console.error('Order created but notification failed:', notificationError.message);
        }

        return res.status(201).json({

            isError: false,

            message: 'สร้าง Order สำเร็จ',

            data: {

                order_id: result.order_id,

                user_id: user_id,

                reservation_id:
                    reservation_id || null,
                table_id: table_id || null

            }

        });

    } catch (error) {

        console.error('Create order error:', error);

        return res.status(error.message?.includes('โต๊ะ') || error.message?.includes('จอง') ? 409 : 500).json({

            isError: true,

            message: error.message || 'เกิดข้อผิดพลาดของ Server',

            errorMessage: error.message

        });

    }

});

app.post('/api/order-details', requireAuth, requireActiveUser, async (req, res) => {

    try {

        const {
            order_id,
            menu_id,
            quantity,
            spicy_id,
            serving_id,
            rice_id,
            egg_id,
            note,
            selected_options
        } = req.body || {};

        const orderId = Number(order_id);
        const menuId = Number(menu_id);
        const itemQuantity = Number(quantity);
        if (!Number.isInteger(orderId) || orderId < 1 || !Number.isInteger(menuId) || menuId < 1 ||
            !Number.isInteger(itemQuantity) || itemQuantity < 1 || itemQuantity > 50) {

            return res.status(400).json({

                isError: true,

                message:
                    'กรุณาระบุ order_id, menu_id, quantity และ price'

            });

        }

        const [orders] = await pool.query(
            'SELECT order_id, user_id, order_status FROM `order` WHERE order_id = ? LIMIT 1',
            [orderId]
        );
        if (!orders.length) return res.status(404).json({ isError: true, message: 'ไม่พบออร์เดอร์' });
        const order = orders[0];
        if (Number(order.user_id) !== Number(req.authUser.sub) && !(await isCurrentAdmin(req.authUser.sub))) {
            return res.status(403).json({ isError: true, message: 'ไม่มีสิทธิ์แก้ไขออร์เดอร์นี้' });
        }
        if (!['รอรับออร์เดอร์', 'รอทำ'].includes(order.order_status)) {
            return res.status(409).json({ isError: true, message: 'ออร์เดอร์นี้ส่งรายการเพิ่มไม่ได้แล้ว' });
        }

        const menu = await menuModel.getMenuById(Number(menu_id));
        if (!menu) {
            return res.status(409).json({ isError: true, message: 'เมนูนี้หยุดขายแล้ว กรุณาเลือกเมนูอื่น' });
        }

        const selectionResult = resolveMenuSelections(menu, selected_options ?? []);
        if (selectionResult.error) return res.status(400).json({ isError: true, message: selectionResult.error });
        const finalPrice = Number(menu.price) + selectionResult.extraPrice;
        if (!Number.isFinite(finalPrice) || finalPrice < 0) return res.status(400).json({ isError: true, message: 'ราคาเมนูไม่ถูกต้อง' });

        const result =
            await orderDetailModel.createOrderDetail({

                order_id: orderId,

                menu_id: menuId,

                quantity: itemQuantity,

                price: finalPrice,

                spicy_id: spicy_id || null,

                serving_id: serving_id || null,

                rice_id: rice_id || null,

                egg_id: egg_id || null,

                note: note || null,
                selected_options: JSON.stringify(selectionResult.snapshot)

            });

        return res.status(201).json({

            isError: false,

            message: 'สร้าง Order Detail สำเร็จ',

            data: {

                orderdetail_id:
                    result.orderdetail_id,

                order_id: orderId,

                menu_id: menuId,

                quantity: quantity,

                price: finalPrice

            }

        });

    } catch (error) {

        console.error(
            'Create order detail error:',
            error
        );

        const conflict = /ออร์เดอร์|รายการเพิ่มไม่ได้/.test(error.message || '');
        return res.status(conflict ? 409 : 500).json({

            isError: true,

            message: conflict ? error.message : 'เกิดข้อผิดพลาดของ Server',

            errorMessage:
                error.message

        });

    }

});

app.get('/api/orders/:id/details', requireAuth, async (req, res) => {

    try {

        const orderId = Number(req.params.id);

        if (!Number.isInteger(orderId) || orderId <= 0) {

            return res.status(400).json({

                isError: true,

                data: [],

                errorMessage: 'order_id ไม่ถูกต้อง'

            });

        }

        const [ownedOrder] = await pool.query(
            'SELECT order_id FROM `order` WHERE order_id = ? AND user_id = ? LIMIT 1',
            [orderId, req.authUser.sub]
        );
        if (!ownedOrder.length && !(await isCurrentAdmin(req.authUser.sub))) {
            return res.status(403).json({ isError: true, message: 'ไม่มีสิทธิ์ดูออร์เดอร์นี้', data: [] });
        }

        const result =
            await orderDetailModel.getOrderDetailsByOrderId(
                orderId
            );

        return res.json({

            isError: false,

            data: result,

            errorMessage: ""

        });

    } catch (error) {

        console.error(
            'Get order details error:',
            error
        );

        return res.status(500).json({

            isError: true,

            data: [],

            errorMessage: error.message

        });

    }

});

app.patch('/api/orders/:orderId/details/:detailId', requireAuth, requireActiveUser, async (req, res) => {
    const orderId = Number(req.params.orderId);
    const detailId = Number(req.params.detailId);
    const { menu_id, quantity, selected_options, note } = req.body || {};
    const menuId = Number(menu_id);
    const count = Number(quantity);
    if (![orderId, detailId, menuId, count].every(Number.isInteger) ||
        orderId < 1 || detailId < 1 || menuId < 1 || count < 1 || count > 99 ||
        !Array.isArray(selected_options) ||
        (note != null && (typeof note !== 'string' || note.length > 500))) {
        return res.status(400).json({ isError: true, message: 'รายละเอียดอาหารไม่ถูกต้อง' });
    }

    let conn;
    try {
        conn = await pool.getConnection();
        await conn.beginTransaction();
        const [orders] = await conn.query(
            'SELECT order_id, order_status FROM `order` WHERE order_id = ? AND user_id = ? FOR UPDATE',
            [orderId, req.authUser.sub]
        );
        if (!orders.length) {
            await conn.rollback();
            return res.status(404).json({ isError: true, message: 'ไม่พบออร์เดอร์ของบัญชีนี้' });
        }
        if (['ยกเลิก', 'รอชำระเงิน', 'รอตรวจสอบการชำระ', 'ชำระแล้ว'].includes(orders[0].order_status)) {
            await conn.rollback();
            return res.status(409).json({ isError: true, message: 'ออร์เดอร์นี้แก้ไขรายละเอียดไม่ได้แล้ว' });
        }
        const [details] = await conn.query(
            'SELECT orderdetail_id FROM order_detail WHERE orderdetail_id = ? AND order_id = ? AND food_status = \'รอทำ\' FOR UPDATE',
            [detailId, orderId]
        );
        if (!details.length) {
            await conn.rollback();
            return res.status(409).json({ isError: true, message: 'รายการนี้เริ่มทำแล้ว หรือไม่อยู่ในออร์เดอร์นี้' });
        }
        const menu = await menuModel.getMenuById(menuId);
        if (!menu) {
            await conn.rollback();
            return res.status(400).json({ isError: true, message: 'เมนูนี้ไม่พร้อมให้สั่งแล้ว' });
        }
        const selectionResult = resolveMenuSelections(menu, selected_options);
        if (selectionResult.error) {
            await conn.rollback();
            return res.status(400).json({ isError: true, message: selectionResult.error });
        }
        const unitPrice = Number(menu.price) + selectionResult.extraPrice;
        await conn.query(
            `UPDATE order_detail SET menu_id = ?, quantity = ?, price = ?, spicy_id = ?,
             serving_id = ?, rice_id = ?, egg_id = ?, note = ?, selected_options = ?
             WHERE orderdetail_id = ? AND order_id = ?`,
            [menuId, count, unitPrice, null, null, null, null, note?.trim() || null,
                JSON.stringify(selectionResult.snapshot), detailId, orderId]
        );
        await conn.commit();
        return res.json({ isError: false, message: 'แก้ไขรายละเอียดอาหารแล้ว' });
    } catch (error) {
        if (conn) await conn.rollback();
        console.error('Edit order detail error:', error);
        return res.status(500).json({ isError: true, message: 'แก้ไขรายละเอียดอาหารไม่สำเร็จ' });
    } finally {
        if (conn) conn.release();
    }
});

app.post('/api/orders/:id/cancel', requireAuth, requireActiveUser, async (req, res) => {
    const orderId = Number(req.params.id);
    if (!Number.isInteger(orderId) || orderId < 1) return res.status(400).json({ isError: true, message: 'หมายเลขออร์เดอร์ไม่ถูกต้อง' });
    let conn;
    let order;
    try {
        conn = await pool.getConnection();
        await conn.beginTransaction();
        const [orders] = await conn.query(
            'SELECT order_id, user_id, table_id, order_status FROM `order` WHERE order_id = ? AND user_id = ? FOR UPDATE',
            [orderId, req.authUser.sub]
        );
        if (!orders.length) {
            await conn.rollback();
            return res.status(404).json({ isError: true, message: 'ไม่พบออร์เดอร์ของบัญชีนี้' });
        }
        order = orders[0];
        if (['ชำระแล้ว', 'รอชำระเงิน', 'รอตรวจสอบการชำระ'].includes(order.order_status)) {
            await conn.rollback();
            return res.status(409).json({ isError: true, message: 'ออร์เดอร์นี้ยกเลิกไม่ได้แล้ว' });
        }
        const [startedItems] = await conn.query(
            'SELECT orderdetail_id FROM order_detail WHERE order_id = ? AND food_status <> \'รอทำ\' LIMIT 1 FOR UPDATE',
            [orderId]
        );
        if (startedItems.length) {
            await conn.rollback();
            return res.status(409).json({ isError: true, message: 'ร้านเริ่มทำอาหารบางเมนูแล้ว จึงยกเลิกออร์เดอร์ไม่ได้' });
        }
        await conn.query('UPDATE `order` SET order_status = \'ยกเลิก\' WHERE order_id = ?', [orderId]);
        if (order.table_id != null) {
            const [otherOpenOrders] = await conn.query(
                `SELECT order_id FROM \`order\` WHERE table_id = ? AND user_id = ? AND order_id <> ?
                 AND order_status NOT IN ('ชำระแล้ว', 'ยกเลิก') LIMIT 1`,
                [order.table_id, order.user_id, orderId]
            );
            if (!otherOpenOrders.length) {
                await conn.query(
                    'UPDATE restaurant_table_session SET ended_at = CURRENT_TIMESTAMP() WHERE table_id = ? AND user_id = ? AND ended_at IS NULL',
                    [order.table_id, order.user_id]
                );
            }
        }
        await conn.commit();
        try {
            await notifyUser(order.user_id, {
                type: 'order_status', title: 'ยกเลิกออร์เดอร์แล้ว',
                body: `ออร์เดอร์ #${orderId} ถูกยกเลิกตามคำขอ`, relatedId: orderId
            });
        } catch (notificationError) {
            console.error('Cancel order notification failed:', notificationError.message);
        }
        return res.json({ isError: false, message: 'ยกเลิกออร์เดอร์แล้ว' });
    } catch (error) {
        if (conn) await conn.rollback();
        console.error('Cancel order error:', error);
        return res.status(500).json({ isError: true, message: 'ยกเลิกออร์เดอร์ไม่สำเร็จ' });
    } finally {
        if (conn) conn.release();
    }
});

app.get('/api/availability', async (req, res) => {
    try {
        const { date, time, guests = '1' } = req.query;
        const guestCount = Number(guests);
        const validationError = validateSlot(date, time);
        if (validationError) return res.status(400).json({ isError: true, message: validationError, data: [] });
        if (!Number.isInteger(guestCount) || guestCount < 1) return res.status(400).json({ isError: true, message: 'จำนวนคนไม่ถูกต้อง', data: [] });
        const holiday = await reservationModel.isRestaurantHoliday(date);
        if (holiday) return res.json({ isError: false, data: [], holiday: holiday.holiday_name, message: 'ร้านหยุดในวันนี้' });
        const tables = await reservationModel.getAvailableTables(date, time, guestCount);
        return res.json({ isError: false, data: tables });
    } catch (error) {
        console.error('Availability error:', error);
        return res.status(500).json({ isError: true, message: 'โหลดเวลาว่างไม่สำเร็จ', errorMessage: error.message });
    }
});

app.get('/api/restaurant/holidays', async (req, res) => {
    try {
        const { from, to } = req.query;
        if (!from || !to) return res.status(400).json({ isError: true, message: 'กรุณาระบุช่วงวันที่' });
        return res.json({ isError: false, data: await reservationModel.getHolidays(from, to) });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'โหลดวันหยุดไม่สำเร็จ' });
    }
});

app.post('/api/reservations', requireAuth, requireActiveUser, async (req, res) => {

    try {

        const {
            table_id,
            booking_date,
            dining_date,
            dining_time,
            guests,
            statusreservation_id
        } = req.body || {};

        if (
            !table_id ||
            !booking_date ||
            !dining_date ||
            !dining_time ||
            !guests
        ) {

            return res.status(400).json({

                isError: true,

                message:
                    'กรุณาระบุ user_id, table_id, booking_date, dining_date, dining_time และ guests'

            });

        }

        const user_id = req.authUser.sub;
        const slotError = validateSlot(dining_date, dining_time);
        if (slotError) return res.status(400).json({ isError: true, message: slotError });
        if (!Number.isInteger(Number(guests)) || Number(guests) < 1) {
            return res.status(400).json({ isError: true, message: 'จำนวนคนต้องเป็นจำนวนเต็มตั้งแต่ 1 คนขึ้นไป' });
        }
        const holiday = await reservationModel.isRestaurantHoliday(dining_date);
        if (holiday) return res.status(400).json({ isError: true, message: `ร้านหยุด: ${holiday.holiday_name}` });

        const bookingDate = bangkokDateTime().date;

        const result =
            await reservationModel.createReservation({

                user_id: user_id,

                table_id: table_id,

                booking_date: bookingDate,

                dining_date: dining_date,

                dining_time: dining_time,

                guests: guests,

                statusreservation_id: 1

            });

        try {
            await notifyUser(user_id, {
                type: 'reservation_status',
                title: 'ยืนยันการจองแล้ว',
                body: `โต๊ะของคุณยืนยันแล้ว วันที่ ${dining_date} เวลา ${dining_time}`,
                relatedId: result.reservation_id
            });
        } catch (notificationError) {
            console.error('Reservation created but notification failed:', notificationError.message);
        }

        return res.status(201).json({

            isError: false,

            message: 'สร้าง Reservation สำเร็จ',

            data: {

                reservation_id:
                    result.reservation_id,

                user_id: user_id,

                table_id: table_id,

                booking_date: bookingDate,

                dining_date: dining_date,

                dining_time: dining_time,

                guests: guests,

                statusreservation_id: 1

            }

        });

    } catch (error) {

        console.error(
            'Create reservation error:',
            error
        );

        const ruleConflict = ['ยังมีออร์เดอร์', 'รายการจอง', 'โต๊ะ', 'ความจุ', 'บัญชี'].some((text) => error.message?.includes(text));
        return res.status(ruleConflict ? 409 : 500).json({

            isError: true,

            message: ruleConflict ? error.message : 'เกิดข้อผิดพลาดของ Server',

            errorMessage:
                error.message

        });

    }

});

app.get('/api/reservations/:id', requireAuth, async (req, res) => {

    try {

        const reservationId =
            Number(req.params.id);

        if (
            !Number.isInteger(reservationId) ||
            reservationId <= 0
        ) {

            return res.status(400).json({

                isError: true,

                data: null,

                errorMessage:
                    'reservation_id ไม่ถูกต้อง'

            });

        }

        const result =
            await reservationModel.getReservationById(
                reservationId
            );

        if (!result) {

            return res.status(404).json({

                isError: true,

                data: null,

                errorMessage:
                    'ไม่พบ Reservation ที่ต้องการ'

            });

        }

        if (Number(result.user_id) !== Number(req.authUser.sub) && !(await isCurrentAdmin(req.authUser.sub))) {
            return res.status(403).json({ isError: true, data: null, errorMessage: 'ไม่มีสิทธิ์ดูรายการจองนี้' });
        }

        return res.json({

            isError: false,

            data: result,

            errorMessage: ""

        });

    } catch (error) {

        console.error(
            'Get reservation error:',
            error
        );

        return res.status(500).json({

            isError: true,

            data: null,

            errorMessage:
                error.message

        });

    }

});

app.get('/api/users/:id/reservations', requireAuth, async (req, res) => {

    try {

        const userId =
            Number(req.params.id);

        if (
            !Number.isInteger(userId) ||
            userId <= 0
        ) {

            return res.status(400).json({

                isError: true,

                data: [],

                errorMessage:
                    'user_id ไม่ถูกต้อง'

            });

        }

        if (Number(req.authUser.sub) !== userId && !(await isCurrentAdmin(req.authUser.sub))) {
            return res.status(403).json({ isError: true, data: [], errorMessage: 'ไม่มีสิทธิ์ดูข้อมูลนี้' });
        }

        const result =
            await reservationModel.getReservationsByUserId(
                userId,
                { historyOnly: req.query.view === 'history' }
            );

        return res.json({

            isError: false,

            data: result,

            errorMessage: ""

        });

    } catch (error) {

        console.error(
            'Get user reservations error:',
            error
        );

        return res.status(500).json({

            isError: true,

            data: [],

            errorMessage:
                error.message

        });

    }

});

app.get('/api/orders/:id', requireAuth, async (req, res) => {

    try {

        const orderId = Number(req.params.id);

        if (
            !Number.isInteger(orderId) ||
            orderId <= 0
        ) {

            return res.status(400).json({

                isError: true,

                data: null,

                errorMessage:
                    'order_id ไม่ถูกต้อง'

            });

        }

        const result =
            await orderModel.getOrderById(orderId);

        if (!result) {

            return res.status(404).json({

                isError: true,

                data: null,

                errorMessage:
                    'ไม่พบ Order ที่ต้องการ'

            });

        }

        if (Number(result.user_id) !== Number(req.authUser.sub) && !(await isCurrentAdmin(req.authUser.sub))) {
            return res.status(403).json({ isError: true, data: null, errorMessage: 'ไม่มีสิทธิ์ดูออร์เดอร์นี้' });
        }

        return res.json({

            isError: false,

            data: result,

            errorMessage: ""

        });

    } catch (error) {

        console.error(
            'Get order error:',
            error
        );

        return res.status(500).json({

            isError: true,

            data: null,

            errorMessage:
                error.message

        });

    }

});

app.get('/api/users/:id/orders', requireAuth, async (req, res) => {
    const userId = Number(req.params.id);
    if (userId !== Number(req.authUser.sub) && !(await isCurrentAdmin(req.authUser.sub))) {
        return res.status(403).json({ isError: true, message: 'ไม่มีสิทธิ์ดูประวัติออร์เดอร์นี้' });
    }
    try {
        const orders = await orderModel.getOrdersByUserId(userId);
        for (const order of orders) {
            const [sum] = await pool.query(
                'SELECT COALESCE(SUM(quantity * price), 0) AS total FROM order_detail WHERE order_id = ?',
                [order.order_id]
            );
            order.total = sum[0].total;
        }
        return res.json({ isError: false, data: orders });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'โหลดประวัติออร์เดอร์ไม่สำเร็จ' });
    }
});

app.post('/api/reservations/:id/cancel', requireAuth, requireActiveUser, async (req, res) => {
    try {
        const reservationId = Number(req.params.id);
        const reservation = await reservationModel.cancelForUser(reservationId, req.authUser.sub);
        await notifyUser(req.authUser.sub, {
            type: 'reservation_status', title: 'ยกเลิกการจองแล้ว',
            body: `ยกเลิกการจองวันที่ ${reservation.dining_date} เวลา ${reservation.dining_time} แล้ว`,
            relatedId: reservationId
        });
        return res.json({ isError: false, message: 'ยกเลิกการจองสำเร็จ' });
    } catch (error) {
        return res.status(400).json({ isError: true, message: error.message });
    }
});

app.post('/api/push-devices', requireAuth, async (req, res) => {
    try {
        const { fcm_token, platform } = req.body || {};
        if (!fcm_token) return res.status(400).json({ isError: true, message: 'ไม่พบ device token' });
        await pool.query(
            `INSERT INTO push_device (user_id, fcm_token, platform) VALUES (?, ?, ?)
             ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), platform = VALUES(platform)`,
            [req.authUser.sub, fcm_token, platform || null]
        );
        return res.json({ isError: false });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'บันทึกอุปกรณ์แจ้งเตือนไม่สำเร็จ' });
    }
});

app.get('/api/notification-preference', requireAuth, async (req, res) => {
    try {
        const [[user]] = await pool.query(
            'SELECT notification_enabled FROM `user` WHERE user_id = ? LIMIT 1',
            [req.authUser.sub]
        );
        if (!user) return res.status(404).json({ isError: true, message: 'ไม่พบบัญชีผู้ใช้' });
        return res.json({ isError: false, data: { enabled: Number(user.notification_enabled) === 1 } });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'โหลดการตั้งค่าการแจ้งเตือนไม่สำเร็จ' });
    }
});

app.patch('/api/notification-preference', requireAuth, async (req, res) => {
    if (typeof req.body?.enabled !== 'boolean') {
        return res.status(400).json({ isError: true, message: 'ระบุสถานะ enabled เป็น true หรือ false' });
    }
    try {
        const [result] = await pool.query(
            'UPDATE `user` SET notification_enabled = ? WHERE user_id = ?',
            [req.body.enabled ? 1 : 0, req.authUser.sub]
        );
        if (!result.affectedRows) {
            const [[user]] = await pool.query('SELECT user_id FROM `user` WHERE user_id = ? LIMIT 1', [req.authUser.sub]);
            if (!user) return res.status(404).json({ isError: true, message: 'ไม่พบบัญชีผู้ใช้' });
        }
        const [[saved]] = await pool.query(
            'SELECT notification_enabled FROM `user` WHERE user_id = ? LIMIT 1',
            [req.authUser.sub]
        );
        return res.json({ isError: false, data: { enabled: Number(saved.notification_enabled) === 1 } });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'บันทึกการตั้งค่าการแจ้งเตือนไม่สำเร็จ' });
    }
});

app.get('/api/notifications', requireAuth, async (req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT notification_id, notification_type, title, body, related_id, is_read,
                    notifications_enabled, sent_at
             FROM customer_notification WHERE user_id = ? ORDER BY sent_at DESC LIMIT 100`,
            [req.authUser.sub]
        );
        return res.json({ isError: false, data: rows });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'โหลดการแจ้งเตือนไม่สำเร็จ' });
    }
});

app.patch('/api/notifications/:id/read', requireAuth, async (req, res) => {
    try {
        await pool.query('UPDATE customer_notification SET is_read = 1 WHERE notification_id = ? AND user_id = ?', [req.params.id, req.authUser.sub]);
        return res.json({ isError: false });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'อัปเดตการแจ้งเตือนไม่สำเร็จ' });
    }
});

app.get('/api/orders/:id/payment-qr', requireAuth, requireActiveUser, async (req, res) => {
    try {
        const orderId = Number(req.params.id);
        if (!Number.isInteger(orderId) || orderId < 1) return res.status(400).json({ isError: true, message: 'หมายเลขออร์เดอร์ไม่ถูกต้อง' });
        const order = await orderModel.getOrderById(orderId);
        if (!order || Number(order.user_id) !== Number(req.authUser.sub)) return res.status(404).json({ isError: true, message: 'ไม่พบออร์เดอร์' });
        if (order.order_status === 'ชำระแล้ว') return res.status(409).json({ isError: true, message: 'ออร์เดอร์นี้ชำระเงินแล้ว' });
        if (!['รอชำระเงิน', 'ชำระเงินไม่ผ่าน'].includes(order.order_status)) return res.status(409).json({ isError: true, message: 'ยังไม่สามารถชำระออร์เดอร์นี้ได้' });
        const [items] = await pool.query(
            `SELECT od.orderdetail_id, od.menu_id, m.menu_name, od.quantity, od.price, od.food_status
             FROM order_detail od JOIN menu m ON m.menu_id = od.menu_id WHERE od.order_id = ?`,
            [orderId]
        );
        if (!items.length || items.some((item) => item.food_status !== 'ทำเสร็จแล้ว')) {
            return res.status(409).json({ isError: true, message: 'จะแสดง QR หลังอาหารทุกรายการทำเสร็จแล้ว' });
        }
        const amount = items.reduce((sum, item) => sum + Number(item.quantity) * Number(item.price), 0);
        const qrPayload = makePromptPayPayload(currentPromptPayId(), amount);
        return res.json({ isError: false, data: { order_id: orderId, amount, qr_payload: qrPayload, promptpay_id: currentPromptPayId(), items } });
    } catch (error) {
        return res.status(400).json({ isError: true, message: error.message });
    }
});

app.get('/api/orders/:id/payment-status', requireAuth, async (req, res) => {
    try {
        const order = await orderModel.getOrderById(Number(req.params.id));
        if (!order || Number(order.user_id) !== Number(req.authUser.sub)) return res.status(404).json({ isError: true, message: 'ไม่พบออร์เดอร์' });
        const payment = await paymentModel.getPaymentForOrder(Number(req.params.id));
        return res.json({ isError: false, data: payment });
    } catch (error) { return res.status(500).json({ isError: true, message: 'ตรวจสอบสถานะชำระเงินไม่สำเร็จ' }); }
});

app.post('/api/orders/:id/payment-slip', requireAuth, requireActiveUser, async (req, res) => {
    let savedFile;
    try {
        const orderId = Number(req.params.id);
        if (!Number.isInteger(orderId) || orderId < 1) return res.status(400).json({ isError: true, message: 'หมายเลขออร์เดอร์ไม่ถูกต้อง' });
        const order = await orderModel.getOrderById(orderId);
        if (!order || Number(order.user_id) !== Number(req.authUser.sub)) return res.status(404).json({ isError: true, message: 'ไม่พบออร์เดอร์' });
        if (!['รอชำระเงิน', 'ชำระเงินไม่ผ่าน'].includes(order.order_status)) return res.status(409).json({ isError: true, message: 'ออร์เดอร์นี้ยังส่งสลิปไม่ได้ หรือส่งสลิปไปแล้ว' });
        const [items] = await pool.query('SELECT quantity, price, food_status FROM order_detail WHERE order_id = ?', [orderId]);
        if (!items.length || items.some((item) => item.food_status !== 'ทำเสร็จแล้ว')) return res.status(409).json({ isError: true, message: 'ยังส่งสลิปไม่ได้จนกว่าอาหารจะทำเสร็จ' });
        const [existing] = await pool.query('SELECT payment_id FROM payment WHERE order_id = ? AND payment_status_id = 3 LIMIT 1', [orderId]);
        if (existing.length) return res.status(409).json({ isError: true, message: 'มีสลิปที่รอตรวจสอบแล้ว' });
        const image = String(req.body?.image_data || '');
        const match = image.match(/^data:image\/(png|jpeg|jpg);base64,([A-Za-z0-9+/=\r\n]+)$/i);
        if (!match) return res.status(400).json({ isError: true, message: 'รูปสลิปต้องเป็น PNG หรือ JPEG' });
        const buffer = Buffer.from(match[2].replace(/\s/g, ''), 'base64');
        if (!buffer.length || buffer.length > 5 * 1024 * 1024) return res.status(400).json({ isError: true, message: 'ไฟล์สลิปต้องมีขนาดไม่เกิน 5 MB' });
        const extension = match[1].toLowerCase() === 'png' ? 'png' : 'jpg';
        const fileName = `order-${orderId}-${Date.now()}.${extension}`;
        const folder = path.join(__dirname, 'storage', 'payment_slips');
        fs.mkdirSync(folder, { recursive: true });
        savedFile = path.join(folder, fileName);
        fs.writeFileSync(savedFile, buffer, { flag: 'wx' });
        const amount = items.reduce((sum, item) => sum + Number(item.quantity) * Number(item.price), 0);
        const paymentId = await paymentModel.createSlipReview({ orderId, userId: req.authUser.sub, amount, imagePath: fileName });
        try {
            const [admins] = await pool.query('SELECT user_id FROM `user` WHERE role_id = 1 AND is_active = 1');
            for (const admin of admins) await notifyUser(admin.user_id, { type: 'payment_review', title: 'มีสลิปใหม่รอตรวจสอบ', body: `ออร์เดอร์ #${orderId} ส่งหลักฐานการชำระแล้ว`, relatedId: orderId });
        } catch (notificationError) {
            console.error('Payment submitted but admin notification failed:', notificationError.message);
        }
        return res.status(201).json({ isError: false, message: 'ส่งสลิปแล้ว รอผู้ดูแลตรวจสอบ', data: { payment_id: paymentId } });
    } catch (error) {
        if (savedFile) {
            try { fs.unlinkSync(savedFile); } catch (_) { /* best-effort cleanup */ }
        }
        console.error('Submit payment slip error:', error);
        const conflict = /ออร์เดอร์|สลิป|ยอดชำระ|อาหารทุกรายการ/.test(error.message || '');
        return res.status(conflict ? 409 : 500).json({ isError: true, message: error.message || 'ส่งสลิปไม่สำเร็จ' });
    }
});

app.get('/api/admin/dashboard', requireAdmin, async (req, res) => {
    try {
        const [[sales]] = await pool.query("SELECT COALESCE(SUM(amount), 0) AS sales FROM payment WHERE payment_status_id = 1 AND payment_date >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01')");
        const [dailySales] = await pool.query("SELECT DATE(payment_date) AS day, COALESCE(SUM(amount), 0) AS sales FROM payment WHERE payment_status_id = 1 AND payment_date >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01') AND payment_date < DATE_ADD(LAST_DAY(CURRENT_DATE()), INTERVAL 1 DAY) GROUP BY DATE(payment_date) ORDER BY day");
        const [[bookingCount]] = await pool.query("SELECT COUNT(*) AS total FROM reservation WHERE dining_date = CURRENT_DATE()");
        const [popularMenus] = await pool.query(
            `SELECT m.menu_id, m.menu_name, SUM(od.quantity) AS plates,
                    SUM(od.quantity * od.price) AS revenue,
                    ROUND(100 * SUM(od.quantity) / NULLIF((SELECT SUM(od2.quantity)
                       FROM order_detail od2 JOIN \`order\` o2 ON o2.order_id = od2.order_id
                       WHERE o2.paid_at >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01')
                         AND o2.order_status = 'ชำระแล้ว'), 0), 1) AS percentage
             FROM order_detail od JOIN menu m ON m.menu_id = od.menu_id
             JOIN \`order\` o ON o.order_id = od.order_id
             WHERE o.paid_at >= DATE_FORMAT(CURRENT_DATE(), '%Y-%m-01') AND o.order_status = 'ชำระแล้ว'
             GROUP BY m.menu_id, m.menu_name ORDER BY plates DESC LIMIT 10`
        );
        return res.json({ isError: false, data: { monthly_sales: sales.sales, daily_sales: dailySales, today_reservations: bookingCount.total, popular_menus: popularMenus } });
    } catch (error) {
        return res.status(500).json({ isError: true, message: 'โหลดสถิติไม่สำเร็จ', errorMessage: error.message });
    }
});

app.get('/api/admin/reservations', requireAdmin, async (_req, res) => {
    try { return res.json({ isError: false, data: await reservationModel.getAdminReservations() }); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดรายการจองไม่สำเร็จ' }); }
});

app.patch('/api/admin/reservations/:id/status', requireAdmin, async (req, res) => {
    const statusId = Number(req.body?.statusreservation_id);
    const names = { 1: 'ยืนยันแล้ว', 2: 'ยกเลิก', 3: 'มาใช้บริการแล้ว', 4: 'รอยืนยัน' };
    if (!names[statusId]) return res.status(400).json({ isError: true, message: 'สถานะการจองไม่ถูกต้อง' });
    try {
        const reservation = await reservationModel.getReservationById(req.params.id);
        if (!reservation) return res.status(404).json({ isError: true, message: 'ไม่พบรายการจอง' });
        await reservationModel.updateStatus(req.params.id, statusId);
        try {
            await notifyUser(reservation.user_id, { type: 'reservation_status', title: `สถานะการจอง: ${names[statusId]}`, body: `การจองวันที่ ${reservation.dining_date} เวลา ${reservation.dining_time} เปลี่ยนเป็น${names[statusId]}`, relatedId: Number(req.params.id) });
        } catch (notificationError) {
            console.error('Reservation status notification failed:', notificationError.message);
        }
        return res.json({ isError: false, message: 'อัปเดตสถานะแล้ว' });
    } catch (error) { return res.status(500).json({ isError: true, message: 'อัปเดตสถานะไม่สำเร็จ' }); }
});

app.get('/api/admin/holidays', requireAdmin, async (_req, res) => {
    try { const [rows] = await pool.query('SELECT holiday_id, holiday_date, holiday_name FROM restaurant_holiday ORDER BY holiday_date'); return res.json({ isError: false, data: rows }); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดวันหยุดไม่สำเร็จ' }); }
});

app.post('/api/admin/holidays', requireAdmin, async (req, res) => {
    const { holiday_date, holiday_name } = req.body || {};
    const parsedHolidayDate = typeof holiday_date === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(holiday_date)
        ? new Date(`${holiday_date}T00:00:00Z`) : null;
    const validHolidayDate = parsedHolidayDate && !Number.isNaN(parsedHolidayDate.valueOf()) &&
        parsedHolidayDate.toISOString().slice(0, 10) === holiday_date;
    if (!validHolidayDate || typeof holiday_name !== 'string' || !holiday_name.trim() || holiday_name.trim().length > 150) {
        return res.status(400).json({ isError: true, message: 'กรุณาระบุวันที่จริงและชื่อวันหยุดไม่เกิน 150 ตัวอักษร' });
    }
    try {
        const [result] = await pool.query('INSERT INTO restaurant_holiday (holiday_date, holiday_name, created_by) VALUES (?, ?, ?)', [holiday_date, holiday_name.trim(), req.authUser.sub]);
        return res.status(201).json({ isError: false, data: { holiday_id: result.insertId } });
    } catch (error) { return res.status(409).json({ isError: true, message: 'วันดังกล่าวมีในปฏิทินแล้ว' }); }
});

app.delete('/api/admin/holidays/:id', requireAdmin, async (req, res) => {
    try { await pool.query('DELETE FROM restaurant_holiday WHERE holiday_id = ?', [req.params.id]); return res.json({ isError: false }); }
    catch (error) { return res.status(500).json({ isError: true, message: 'ลบวันหยุดไม่สำเร็จ' }); }
});

app.get('/api/admin/orders', requireAdmin, async (_req, res) => {
    try { return res.json({ isError: false, data: await orderModel.getAdminOrders() }); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดออร์เดอร์ไม่สำเร็จ' }); }
});

app.get('/api/admin/order-items', requireAdmin, async (_req, res) => {
    try { return res.json({ isError: false, data: await orderDetailModel.getAdminOrderDetails() }); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดรายการอาหารไม่สำเร็จ' }); }
});

app.patch('/api/admin/order-items/:id/accept', requireAdmin, async (req, res) => {
    const detailId = Number(req.params.id);
    if (!Number.isInteger(detailId) || detailId < 1) return res.status(400).json({ isError: true, message: 'หมายเลขรายการอาหารไม่ถูกต้อง' });
    const conn = await pool.getConnection();
    try {
        await conn.beginTransaction();
        const [rows] = await conn.query(
            `SELECT od.orderdetail_id, od.order_id, od.food_status, o.user_id, o.order_status
             FROM order_detail od JOIN \`order\` o ON o.order_id = od.order_id
             WHERE od.orderdetail_id = ? FOR UPDATE`,
            [detailId]
        );
        if (!rows.length) {
            await conn.rollback();
            return res.status(404).json({ isError: true, message: 'ไม่พบรายการอาหาร' });
        }
        const item = rows[0];
        if (!['รอรับออร์เดอร์', 'กำลังทำ'].includes(item.order_status) || item.food_status !== 'รอทำ') {
            await conn.rollback();
            return res.status(409).json({ isError: true, message: 'เมนูนี้ถูกรับไปแล้ว หรือไม่อยู่ในสถานะรอทำ' });
        }
        await conn.query("UPDATE order_detail SET food_status = 'กำลังทำ' WHERE orderdetail_id = ?", [detailId]);
        await conn.query("UPDATE `order` SET order_status = 'กำลังทำ' WHERE order_id = ?", [item.order_id]);
        await conn.commit();
        try {
            await notifyUser(item.user_id, {
                type: 'order_status', title: 'ร้านรับเมนูแล้ว',
                body: `ร้านเริ่มทำอาหารรายการหนึ่งในออร์เดอร์ #${item.order_id} แล้ว`, relatedId: item.order_id
            });
        } catch (notificationError) {
            console.error('Order item accepted but notification failed:', notificationError.message);
        }
        return res.json({ isError: false, message: 'รับเมนูนี้แล้ว' });
    } catch (error) {
        await conn.rollback();
        console.error('Accept order error:', error);
        return res.status(500).json({ isError: true, message: 'รับเมนูไม่สำเร็จ' });
    } finally {
        conn.release();
    }
});

app.patch('/api/admin/order-items/:id/status', requireAdmin, async (req, res) => {
    const status = req.body?.food_status;
    if (!['รอทำ', 'กำลังทำ', 'ทำเสร็จแล้ว'].includes(status)) return res.status(400).json({ isError: true, message: 'สถานะอาหารไม่ถูกต้อง' });
    const detailId = Number(req.params.id);
    if (!Number.isInteger(detailId) || detailId < 1) return res.status(400).json({ isError: true, message: 'หมายเลขรายการอาหารไม่ถูกต้อง' });
    const conn = await pool.getConnection();
    let orderId;
    let userId;
    let parentStatus;
    try {
        await conn.beginTransaction();
        const [rows] = await conn.query(
            `SELECT od.orderdetail_id, od.order_id, od.food_status, o.user_id, o.order_status
             FROM order_detail od JOIN \`order\` o ON o.order_id = od.order_id
             WHERE od.orderdetail_id = ? FOR UPDATE`,
            [detailId]
        );
        if (!rows.length) {
            await conn.rollback();
            return res.status(404).json({ isError: true, message: 'ไม่พบรายการอาหาร' });
        }
        const item = rows[0];
        if (['ยกเลิก', 'ชำระแล้ว', 'รอตรวจสอบการชำระ'].includes(item.order_status)) {
            await conn.rollback();
            return res.status(409).json({ isError: true, message: 'ออร์เดอร์นี้ปิดแล้ว จึงเปลี่ยนสถานะอาหารไม่ได้' });
        }
        orderId = Number(item.order_id);
        userId = Number(item.user_id);
        await conn.query('UPDATE order_detail SET food_status = ? WHERE orderdetail_id = ?', [status, detailId]);
        const [[summary]] = await conn.query(
            `SELECT COUNT(*) AS total,
                    SUM(food_status = 'ทำเสร็จแล้ว') AS completed,
                    SUM(food_status <> 'รอทำ') AS started
             FROM order_detail WHERE order_id = ?`,
            [orderId]
        );
        if (!Number(summary.total)) throw new Error('ออร์เดอร์ไม่มีรายการอาหาร');
        parentStatus = Number(summary.completed) === Number(summary.total)
            ? 'รอชำระเงิน'
            : Number(summary.started) > 0 ? 'กำลังทำ' : 'รอรับออร์เดอร์';
        await conn.query('UPDATE `order` SET order_status = ? WHERE order_id = ?', [parentStatus, orderId]);
        await conn.commit();
        try {
            await notifyUser(userId, parentStatus === 'รอชำระเงิน'
                ? { type: 'order_ready', title: 'อาหารทำเสร็จแล้ว', body: `ออร์เดอร์ #${orderId} พร้อมชำระเงิน แตะเพื่อดู QR PromptPay`, relatedId: orderId }
                : { type: 'order_status', title: 'สถานะอาหารอัปเดต', body: `ออร์เดอร์ #${orderId}: ${status}`, relatedId: orderId });
        } catch (notificationError) {
            console.error('Order status notification failed:', notificationError.message);
        }
        return res.json({ isError: false, message: 'อัปเดตสถานะอาหารแล้ว' });
    } catch (error) {
        await conn.rollback();
        console.error('Update order item status error:', error);
        return res.status(500).json({ isError: true, message: 'อัปเดตสถานะไม่สำเร็จ' });
    } finally { conn.release(); }
});

app.get('/api/admin/payments', requireAdmin, async (_req, res) => {
    try { return res.json({ isError: false, data: await paymentModel.getAdminPayments() }); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดรายการชำระเงินไม่สำเร็จ' }); }
});

app.get('/api/admin/payments/:id/slip', requireAdmin, async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT payment_image FROM payment WHERE payment_id = ?', [req.params.id]);
        if (!rows.length || !rows[0].payment_image) return res.status(404).json({ isError: true, message: 'ไม่พบสลิป' });
        const file = path.join(__dirname, 'storage', 'payment_slips', path.basename(rows[0].payment_image));
        if (!fs.existsSync(file)) return res.status(404).json({ isError: true, message: 'ไม่พบไฟล์สลิป' });
        return res.sendFile(file);
    } catch (error) { return res.status(500).json({ isError: true, message: 'เปิดสลิปไม่สำเร็จ' }); }
});

app.patch('/api/admin/payments/:id/review', requireAdmin, async (req, res) => {
    try {
        const approved = req.body?.approved === true;
        const payment = await paymentModel.reviewPayment({ paymentId: req.params.id, reviewerId: req.authUser.sub, approved });
        if (payment.order_id) {
            const order = await orderModel.getOrderById(payment.order_id);
            if (order) await notifyUser(order.user_id, {
                type: 'payment_status', title: approved ? 'ยืนยันการชำระเงินแล้ว' : 'ตรวจสอบสลิปไม่ผ่าน',
                body: approved ? `ออร์เดอร์ #${payment.order_id} ชำระเงินเรียบร้อย` : `กรุณาตรวจสอบและส่งสลิปใหม่สำหรับออร์เดอร์ #${payment.order_id}`,
                relatedId: payment.order_id
            });
        }
        return res.json({ isError: false, message: approved ? 'ยืนยันการชำระเงินแล้ว' : 'ปฏิเสธสลิปแล้ว' });
    } catch (error) { return res.status(400).json({ isError: true, message: error.message }); }
});

app.patch('/api/admin/customers/:id/status', requireAdmin, async (req, res) => {
    try {
        const customerId = Number(req.params.id);
        const customer = await userModel.getUserById(customerId);
        if (!customer || Number(customer.role_id) !== 2 || Number(customer.is_deleted) === 1) return res.status(404).json({ isError: true, message: 'ไม่พบลูกค้า' });
        await userModel.setAccountActive(customerId, req.body?.is_active === true);
        return res.json({ isError: false, message: 'อัปเดตบัญชีลูกค้าแล้ว' });
    } catch (error) { return res.status(500).json({ isError: true, message: 'อัปเดตบัญชีไม่สำเร็จ' }); }
});

app.get('/api/admin/customers', requireAdmin, async (_req, res) => {
    try {
        const [rows] = await pool.query(
            `SELECT user_id, username, fullname, phone, email, is_active
             FROM \`user\` WHERE role_id = 2 AND is_deleted = 0 ORDER BY user_id DESC`
        );
        return res.json({ isError: false, data: rows });
    } catch (error) { return res.status(500).json({ isError: true, message: 'โหลดข้อมูลลูกค้าไม่สำเร็จ' }); }
});

app.put('/api/admin/customers/:id', requireAdmin, async (req, res) => {
    const { username, fullname, phone, email } = req.body || {};
    if (typeof fullname !== 'string' || !fullname.trim() || fullname.trim().length > 150) return res.status(400).json({ isError: true, message: 'กรุณาระบุชื่อลูกค้าไม่เกิน 150 ตัวอักษร' });
    const cleanUsername = typeof username === 'string' ? username.trim() : '';
    if (!/^[A-Za-z0-9_.-]{3,50}$/.test(cleanUsername)) return res.status(400).json({ isError: true, message: 'ชื่อผู้ใช้ต้องยาว 3–50 ตัว และใช้ได้เฉพาะ a-z, 0-9, _, ., -' });
    const cleanPhone = typeof phone === 'string' ? phone.trim() : '';
    const normalizedPhone = cleanPhone ? normalizeThaiPhone(cleanPhone) : null;
    const cleanEmail = typeof email === 'string' ? email.trim() : '';
    if ((cleanPhone && !normalizedPhone) || !validEmail(cleanEmail)) return res.status(400).json({ isError: true, message: 'รูปแบบเบอร์โทรศัพท์หรืออีเมลไม่ถูกต้อง' });
    try {
        const customer = await userModel.getUserById(Number(req.params.id));
        if (!customer || Number(customer.role_id) !== 2 || Number(customer.is_deleted) === 1) return res.status(404).json({ isError: true, message: 'ไม่พบลูกค้า' });
        const usernameOwner = await userModel.getUserByUsername(cleanUsername);
        if (usernameOwner && Number(usernameOwner.user_id) !== Number(customer.user_id)) return res.status(409).json({ isError: true, message: 'ชื่อผู้ใช้นี้ถูกใช้แล้ว' });
        if (normalizedPhone) {
            const duplicatePhone = await userModel.getUserByPhone(normalizedPhone);
            if (duplicatePhone && Number(duplicatePhone.user_id) !== Number(customer.user_id)) return res.status(409).json({ isError: true, message: 'เบอร์โทรนี้มีบัญชีผู้ใช้อื่นแล้ว' });
        }
        await userModel.updateUser(req.params.id, { username: cleanUsername, fullname: fullname.trim(), phone: normalizedPhone, email: cleanEmail || null });
        return res.json({ isError: false, message: 'แก้ไขข้อมูลลูกค้าแล้ว' });
    } catch (error) {
        if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ isError: true, message: 'ชื่อผู้ใช้หรือเบอร์โทรนี้มีบัญชีอื่นแล้ว' });
        return res.status(500).json({ isError: true, message: 'แก้ไขข้อมูลลูกค้าไม่สำเร็จ' });
    }
});

app.patch('/api/admin/customers/:id/password', requireAdmin, async (req, res) => {
    const password = req.body?.password;
    if (typeof password !== 'string' || Buffer.byteLength(password, 'utf8') < 8 || Buffer.byteLength(password, 'utf8') > 72) {
        return res.status(400).json({ isError: true, message: 'รหัสผ่านใหม่ต้องมีอย่างน้อย 8 และไม่เกิน 72 ไบต์' });
    }
    try {
        const customer = await userModel.getUserById(Number(req.params.id));
        if (!customer || Number(customer.role_id) !== 2 || Number(customer.is_deleted) === 1) {
            return res.status(404).json({ isError: true, message: 'ไม่พบลูกค้า' });
        }
        const passwordHash = await bcrypt.hash(password, 10);
        const updated = await userModel.setPasswordHash(customer.user_id, passwordHash);
        if (!updated) return res.status(404).json({ isError: true, message: 'ไม่พบลูกค้า' });
        return res.json({ isError: false, message: 'ตั้งรหัสผ่านใหม่แล้ว' });
    } catch (error) {
        console.error('Admin reset customer password error:', error);
        return res.status(500).json({ isError: true, message: 'ตั้งรหัสผ่านใหม่ไม่สำเร็จ' });
    }
});

app.delete('/api/admin/customers/:id', requireAdmin, async (req, res) => {
    try {
        const customerId = Number(req.params.id);
        const customer = await userModel.getUserById(customerId);
        if (!customer || Number(customer.role_id) !== 2 || Number(customer.is_deleted) === 1) {
            return res.status(404).json({ isError: true, message: 'ไม่พบลูกค้า' });
        }
        const randomPassword = crypto.randomBytes(32).toString('hex');
        const passwordHash = await bcrypt.hash(randomPassword, 10);
        const archivedUsername = `deleted_${customerId}_${crypto.randomBytes(6).toString('hex')}`;
        const deleted = await userModel.deleteCustomerAccount({ userId: customerId, archivedUsername, passwordHash });
        if (!deleted) return res.status(404).json({ isError: true, message: 'ไม่พบลูกค้า' });
        return res.json({ isError: false, message: 'ลบบัญชีลูกค้าแล้ว โดยเก็บประวัติรายการเดิมไว้' });
    } catch (error) {
        console.error('Admin delete customer error:', error);
        return res.status(500).json({ isError: true, message: 'ลบบัญชีลูกค้าไม่สำเร็จ' });
    }
});

app.get('/api/admin/menu', requireAdmin, async (_req, res) => {
    try { return res.json(await menuModel.getAllMenu()); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดเมนูไม่สำเร็จ' }); }
});

app.post('/api/admin/menu', requireAdmin, async (req, res) => {
    const { menu_name, price, category, menu_image = null, option_groups = [], statusmenu_id = 1 } = req.body || {};
    if (typeof menu_name !== 'string' || !menu_name.trim() || menu_name.trim().length > 150 || price == null || !Number.isFinite(Number(price)) || Number(price) < 0 || !['ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].includes(category) || ![1, 2].includes(Number(statusmenu_id)) || (menu_image != null && (typeof menu_image !== 'string' || !/^menu-[a-f0-9-]+\.(png|jpe?g|webp)$/i.test(menu_image))) || !validMenuOptionGroups(option_groups)) return res.status(400).json({ isError: true, message: 'ข้อมูลเมนูหรือตัวเลือกไม่ถูกต้อง' });
    try {
        const menuId = await menuModel.createMenu({ menu_name: menu_name.trim(), price: Number(price), category, menu_image, option_groups, statusmenu_id: Number(statusmenu_id) });
        return res.status(201).json({ isError: false, data: { menu_id: menuId } });
    } catch (error) { return res.status(500).json({ isError: true, message: 'เพิ่มเมนูไม่สำเร็จ' }); }
});

app.put('/api/admin/menu/:id', requireAdmin, async (req, res) => {
    const { menu_name, price, category, menu_image = null, option_groups = [], statusmenu_id } = req.body || {};
    if (typeof menu_name !== 'string' || !menu_name.trim() || menu_name.trim().length > 150 || price == null || !Number.isFinite(Number(price)) || Number(price) < 0 || !['ข้าว', 'เส้น', 'น้ำดื่ม', 'อื่นๆ'].includes(category) || ![1, 2].includes(Number(statusmenu_id)) || (menu_image != null && (typeof menu_image !== 'string' || !/^menu-[a-f0-9-]+\.(png|jpe?g|webp)$/i.test(menu_image))) || !validMenuOptionGroups(option_groups)) return res.status(400).json({ isError: true, message: 'ข้อมูลเมนูหรือตัวเลือกไม่ถูกต้อง' });
    try {
        const updated = await menuModel.updateMenu(req.params.id, { menu_name: menu_name.trim(), price: Number(price), category, menu_image, option_groups, statusmenu_id: Number(statusmenu_id) });
        return updated ? res.json({ isError: false }) : res.status(404).json({ isError: true, message: 'ไม่พบเมนู' });
    } catch (error) { return res.status(500).json({ isError: true, message: 'แก้ไขเมนูไม่สำเร็จ' }); }
});

app.delete('/api/admin/menu/:id', requireAdmin, async (req, res) => {
    try {
        const deleted = await menuModel.deleteMenu(req.params.id);
        return deleted ? res.json({ isError: false }) : res.status(404).json({ isError: true, message: 'ไม่พบเมนู' });
    } catch (error) { return res.status(409).json({ isError: true, message: 'ลบเมนูไม่ได้ เนื่องจากมีประวัติออร์เดอร์อ้างอิงอยู่' }); }
});

app.get('/api/admin/tables', requireAdmin, async (_req, res) => {
    try { return res.json(await tableModel.getAllTables()); }
    catch (error) { return res.status(500).json({ isError: true, message: 'โหลดโต๊ะไม่สำเร็จ' }); }
});

app.post('/api/admin/tables', requireAdmin, async (req, res) => {
    const { table_number, capacity } = req.body || {};
    if (!Number.isInteger(Number(table_number)) || Number(table_number) < 1 || !Number.isInteger(Number(capacity)) || Number(capacity) < 1) return res.status(400).json({ isError: true, message: 'หมายเลขโต๊ะหรือความจุไม่ถูกต้อง' });
    try {
        const tableId = await tableModel.createTable({ table_number: Number(table_number), capacity: Number(capacity) });
        return res.status(201).json({ isError: false, data: { table_id: tableId } });
    } catch (error) { return res.status(409).json({ isError: true, message: 'หมายเลขโต๊ะนี้มีแล้ว' }); }
});

app.put('/api/admin/tables/:id', requireAdmin, async (req, res) => {
    const { table_number, capacity, statustable_id } = req.body || {};
    if (!Number.isInteger(Number(table_number)) || Number(table_number) < 1 || !Number.isInteger(Number(capacity)) || Number(capacity) < 1 || ![1, 2].includes(Number(statustable_id))) return res.status(400).json({ isError: true, message: 'ข้อมูลโต๊ะไม่ถูกต้อง' });
    try {
        const updated = await tableModel.updateTable(req.params.id, { table_number, capacity, statustable_id });
        return updated ? res.json({ isError: false }) : res.status(404).json({ isError: true, message: 'ไม่พบโต๊ะ' });
    } catch (error) { return res.status(409).json({ isError: true, message: 'แก้ไขโต๊ะไม่สำเร็จ' }); }
});

app.delete('/api/admin/tables/:id/walk-in-session', requireAdmin, async (req, res) => {
    try {
        const cleared = await tableModel.clearWalkInSession(req.params.id);
        return cleared
            ? res.json({ isError: false, message: 'ปิดรอบการใช้โต๊ะแล้ว' })
            : res.status(404).json({ isError: true, message: 'โต๊ะนี้ไม่มีรอบใช้งานที่เปิดอยู่' });
    } catch (error) {
        console.error('Clear table session error:', error);
        return res.status(500).json({ isError: true, message: 'ปิดรอบการใช้โต๊ะไม่สำเร็จ' });
    }
});

app.get('/api/stats/popular', requireAuth, async (req, res) => {
    try {
        const month = String(req.query.month || '');
        if (!/^\d{4}-\d{2}$/.test(month)) return res.status(400).json({ isError: true, message: 'ระบุเดือนในรูปแบบ YYYY-MM' });
        const [rows] = await pool.query(
            `SELECT m.menu_id, m.menu_name, SUM(od.quantity) AS plates,
                    ROUND(100 * SUM(od.quantity) / NULLIF((SELECT SUM(od2.quantity)
                      FROM order_detail od2 JOIN \`order\` o2 ON o2.order_id = od2.order_id
                      WHERE o2.order_status = 'ชำระแล้ว' AND DATE_FORMAT(o2.paid_at, '%Y-%m') = ?), 0), 1) AS percentage
             FROM order_detail od JOIN menu m ON m.menu_id = od.menu_id
             JOIN \`order\` o ON o.order_id = od.order_id
             WHERE o.order_status = 'ชำระแล้ว' AND DATE_FORMAT(o.paid_at, '%Y-%m') = ?
             GROUP BY m.menu_id, m.menu_name ORDER BY plates DESC`,
            [month, month]
        );
        return res.json({ isError: false, data: rows });
    } catch (error) { return res.status(500).json({ isError: true, message: 'โหลดสถิติเมนูไม่สำเร็จ' }); }
});

// Keep API failures machine-readable so Flutter can show the server's message
// instead of failing while decoding Express' default HTML error page.
app.use((req, res) => {
    res.status(404).json({ isError: true, message: 'ไม่พบ API ที่ร้องขอ' });
});

app.use((error, _req, res, _next) => {
    console.error('Unhandled API error:', error);
    const status = error.type === 'entity.too.large' ? 413 :
        error.type === 'entity.parse.failed' ? 400 : 500;
    const message = status === 413 ? 'ข้อมูลที่ส่งมีขนาดใหญ่เกินกำหนด' :
        status === 400 ? 'รูปแบบข้อมูล JSON ไม่ถูกต้อง' : 'เกิดข้อผิดพลาดของ Server';
    if (!res.headersSent) res.status(status).json({ isError: true, message });
});

app.listen(PORT, () => {

    if (process.env.AUTH_TOKEN_SECRET === undefined || process.env.AUTH_TOKEN_SECRET.length < 32) {
        console.warn('Set AUTH_TOKEN_SECRET to a random value of at least 32 characters before using the app.');
    }
    if (!process.env.PROMPTPAY_ID) console.warn('Set PROMPTPAY_ID before using PromptPay payments.');
    startReservationReminderWorker();

    console.log(
        `Server running at http://localhost:${PORT}`
    );

});
