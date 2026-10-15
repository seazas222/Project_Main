const crypto = require('crypto');
const userModel = require('../models/user');

const secret = process.env.AUTH_TOKEN_SECRET;
if (typeof secret !== 'string' || Buffer.byteLength(secret, 'utf8') < 32) {
    throw new Error('AUTH_TOKEN_SECRET must be set to a random value of at least 32 bytes before starting the server.');
}

function encode(value) {
    return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function issueToken(user) {
    const now = Math.floor(Date.now() / 1000);
    const header = encode({ alg: 'HS256', typ: 'JWT' });
    const payload = encode({
        sub: Number(user.user_id),
        role_id: Number(user.role_id),
        iat: now,
        exp: now + (12 * 60 * 60)
    });
    const input = `${header}.${payload}`;
    const signature = crypto.createHmac('sha256', secret).update(input).digest('base64url');
    return `${input}.${signature}`;
}

function verifyToken(token) {
    const parts = String(token || '').split('.');
    if (parts.length !== 3) return null;
    const input = `${parts[0]}.${parts[1]}`;
    const expected = crypto.createHmac('sha256', secret).update(input).digest();
    let actual;
    try {
        actual = Buffer.from(parts[2], 'base64url');
    } catch (_) {
        return null;
    }
    if (actual.length !== expected.length || !crypto.timingSafeEqual(actual, expected)) return null;
    try {
        const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
        if (!payload.sub || !payload.exp || payload.exp <= Math.floor(Date.now() / 1000)) return null;
        return payload;
    } catch (_) {
        return null;
    }
}

async function requireAuth(req, res, next) {
    const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
    const tokenUser = verifyToken(token);
    if (!tokenUser) return res.status(401).json({ isError: true, message: 'กรุณาเข้าสู่ระบบใหม่' });
    try {
        const account = await userModel.getUserById(tokenUser.sub);
        if (!account || Number(account.is_active) !== 1 || Number(account.is_deleted) === 1) {
            return res.status(403).json({ isError: true, message: 'บัญชีนี้ถูกระงับการใช้งาน' });
        }
        req.authUser = {
            ...tokenUser,
            role_id: Number(account.role_id),
            account_active: true,
            account_deleted: false
        };
        return next();
    } catch (error) {
        console.error('Authentication account check failed:', error.message);
        return res.status(500).json({ isError: true, message: 'ตรวจสอบบัญชีไม่สำเร็จ' });
    }
}

function requireAdmin(req, res, next) {
    requireAuth(req, res, () => {
        if (Number(req.authUser.role_id) !== 1) {
            return res.status(403).json({ isError: true, message: 'เฉพาะผู้ดูแลร้านเท่านั้น' });
        }
        next();
    });
}

module.exports = { issueToken, verifyToken, requireAuth, requireAdmin };
