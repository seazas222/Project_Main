const express = require('express');
const cors = require('cors');
const bcrypt = require('bcrypt');

const userModel = require('./models/user');
const menuModel = require('./models/menu');
const orderModel = require('./models/order');
const orderDetailModel = require('./models/order_detail');
const reservationModel = require('./models/reservation');

const app = express();

const PORT = 3000;

// MIDDLEWARE

app.use(cors());

app.use(express.json());

// TEST SERVER

app.get('/', (req, res) => {

    res.json({
        isError: false,
        message: 'Server is running'
    });

});

// GET ALL USERS

app.get('/api/users', async (req, res) => {

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


// LOGIN

app.post('/api/login', async (req, res) => {

    try {

        const {
            username,
            password
        } = req.body;


        // ตรวจข้อมูล
        if (!username || !password) {

            return res.status(400).json({
                isError: true,
                message: 'กรุณากรอก username และ password'
            });

        }


        // ค้นหา User
        const user =
            await userModel.getUserByUsername(username);


        // ไม่พบ User
        if (!user) {

            return res.status(401).json({
                isError: true,
                message: 'Username หรือ Password ไม่ถูกต้อง'
            });

        }


        // ตรวจ Password
        const passwordMatch =
            await bcrypt.compare(
                password,
                user.password
            );


        // Password ไม่ตรง
        if (!passwordMatch) {

            return res.status(401).json({
                isError: true,
                message: 'Username หรือ Password ไม่ถูกต้อง'
            });

        }


        // Login สำเร็จ
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

                user_image: user.user_image

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


// REGISTER

app.post('/api/register', async (req, res) => {

    try {

        const {
            username,
            password,
            fullname,
            phone,
            email
        } = req.body;


        // ตรวจข้อมูล
        if (!username || !password || !fullname) {

            return res.status(400).json({

                isError: true,

                message: 'กรุณากรอกข้อมูลให้ครบ'

            });

        }


        // ตรวจ Username ซ้ำ
        const existingUser =
            await userModel.getUserByUsername(username);


        if (existingUser) {

            return res.status(409).json({

                isError: true,

                message: 'Username นี้มีผู้ใช้งานแล้ว'

            });

        }


        // Hash Password
        const hashedPassword =
            await bcrypt.hash(password, 10);


        // สร้าง User
        const result =
            await userModel.createUser({

                username: username,

                password: hashedPassword,

                fullname: fullname,

                phone: phone || null,

                email: email || null,

                role_id: 2,

                user_image: null

            });


        return res.status(201).json({

            isError: false,

            message: 'Register success',

            data: {

                user_id: result.user_id,

                username: username,

                fullname: fullname

            }

        });

    } catch (error) {

        console.error('Register error:', error);

        return res.status(500).json({

            isError: true,

            message: 'เกิดข้อผิดพลาดของ Server'

        });

    }

});

// UPDATE USER

app.put('/api/users/:id', async (req, res) => {

    try {

        const userId = Number(req.params.id);

        const {
            fullname,
            phone,
            email
        } = req.body;

        // ตรวจ user_id
        if (!Number.isInteger(userId) || userId <= 0) {

            return res.status(400).json({
                isError: true,
                message: 'user_id ไม่ถูกต้อง'
            });

        }

        // ตรวจ fullname
        if (!fullname || !fullname.trim()) {

            return res.status(400).json({
                isError: true,
                message: 'กรุณากรอกชื่อ'
            });

        }

        // ตรวจว่ามี user นี้จริง
        const existingUser =
            await userModel.getUserById(userId);

        if (!existingUser) {

            return res.status(404).json({
                isError: true,
                message: 'ไม่พบผู้ใช้งาน'
            });

        }

        // Update
        await userModel.updateUser(
            userId,
            {
                fullname: fullname.trim(),
                phone: phone || null,
                email: email || null
            }
        );

        // ดึงข้อมูลล่าสุดกลับมา
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

        return res.status(500).json({

            isError: true,

            message: 'เกิดข้อผิดพลาดของ Server'

        });

    }

});

// GET USER BY ID

getUserById: async (userId) => {

    let conn;

    try {

        conn = await pool.getConnection();

        const sql = `
            SELECT
                user_id,
                username,
                fullname,
                phone,
                email,
                role_id,
                user_image
            FROM \`user\`
            WHERE user_id = ?
            LIMIT 1
        `;

        const [rows] = await conn.query(
            sql,
            [userId]
        );

        return rows[0] || null;

    } finally {

        if (conn) {
            conn.release();
        }

    }
},

// GET ALL MENU

app.get('/api/menu', async (req, res) => {

    try {

        const result = await menuModel.getAllMenu();

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

// GET MENU BY ID

app.get('/api/menu/:id', async (req, res) => {

    try {

        const menuId = Number(req.params.id);


        // ตรวจสอบ ID
        if (!Number.isInteger(menuId) || menuId <= 0) {

            return res.status(400).json({

                isError: true,

                data: null,

                errorMessage: 'menu_id ไม่ถูกต้อง'

            });

        }


        // ค้นหาเมนู
        const menu =
            await menuModel.getMenuById(menuId);


        // ไม่พบเมนู
        if (!menu) {

            return res.status(404).json({

                isError: true,

                data: null,

                errorMessage: 'ไม่พบเมนูที่ต้องการ'

            });

        }


        // พบเมนู
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

// CREATE ORDER

app.post('/api/orders', async (req, res) => {

    try {

        const {
            user_id,
            reservation_id
        } = req.body;


        // ตรวจ user_id
        if (!user_id) {

            return res.status(400).json({

                isError: true,

                message: 'กรุณาระบุ user_id'

            });

        }


        // สร้าง Order
        const result =
            await orderModel.createOrder({

                user_id: user_id,

                reservation_id:
                    reservation_id || null

            });


        return res.status(201).json({

            isError: false,

            message: 'สร้าง Order สำเร็จ',

            data: {

                order_id: result.order_id,

                user_id: user_id,

                reservation_id:
                    reservation_id || null

            }

        });

    } catch (error) {

        console.error('Create order error:', error);

        return res.status(500).json({

            isError: true,

            message: 'เกิดข้อผิดพลาดของ Server',

            errorMessage: error.message

        });

    }

});

// CREATE ORDER DETAIL

app.post('/api/order-details', async (req, res) => {

    try {

        const {
            order_id,
            menu_id,
            quantity,
            price,
            spicy_id,
            serving_id,
            rice_id,
            egg_id,
            note
        } = req.body || {};

        // ตรวจข้อมูลจำเป็น
        if (!order_id || !menu_id || !quantity || price == null) {

            return res.status(400).json({

                isError: true,

                message:
                    'กรุณาระบุ order_id, menu_id, quantity และ price'

            });

        }


        // สร้าง Order Detail
        const result =
            await orderDetailModel.createOrderDetail({

                order_id: order_id,

                menu_id: menu_id,

                quantity: quantity,

                price: price,

                spicy_id: spicy_id || null,

                serving_id: serving_id || null,

                rice_id: rice_id || null,

                egg_id: egg_id || null,

                note: note || null

            });


        return res.status(201).json({

            isError: false,

            message: 'สร้าง Order Detail สำเร็จ',

            data: {

                orderdetail_id:
                    result.orderdetail_id,

                order_id: order_id,

                menu_id: menu_id,

                quantity: quantity,

                price: price

            }

        });

    } catch (error) {

        console.error(
            'Create order detail error:',
            error
        );

        return res.status(500).json({

            isError: true,

            message:
                'เกิดข้อผิดพลาดของ Server',

            errorMessage:
                error.message

        });

    }

});

// GET ORDER DETAILS

app.get('/api/orders/:id/details', async (req, res) => {

    try {

        const orderId = Number(req.params.id);


        // ตรวจสอบ order_id
        if (!Number.isInteger(orderId) || orderId <= 0) {

            return res.status(400).json({

                isError: true,

                data: [],

                errorMessage: 'order_id ไม่ถูกต้อง'

            });

        }


        // ค้นหา Order Detail
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

// CREATE RESERVATION

app.post('/api/reservations', async (req, res) => {

    try {

        const {
            user_id,
            table_id,
            booking_date,
            dining_date,
            dining_time,
            guests,
            statusreservation_id
        } = req.body || {};


        // ตรวจข้อมูลจำเป็น
        if (
            !user_id ||
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


        // สร้าง Reservation
        const result =
            await reservationModel.createReservation({

                user_id: user_id,

                table_id: table_id,

                booking_date: booking_date,

                dining_date: dining_date,

                dining_time: dining_time,

                guests: guests,

                statusreservation_id:
                    statusreservation_id || 1

            });


        return res.status(201).json({

            isError: false,

            message: 'สร้าง Reservation สำเร็จ',

            data: {

                reservation_id:
                    result.reservation_id,

                user_id: user_id,

                table_id: table_id,

                booking_date: booking_date,

                dining_date: dining_date,

                dining_time: dining_time,

                guests: guests,

                statusreservation_id:
                    statusreservation_id || 1

            }

        });

    } catch (error) {

        console.error(
            'Create reservation error:',
            error
        );

        return res.status(500).json({

            isError: true,

            message:
                'เกิดข้อผิดพลาดของ Server',

            errorMessage:
                error.message

        });

    }

});

// GET RESERVATION BY ID

app.get('/api/reservations/:id', async (req, res) => {

    try {

        const reservationId =
            Number(req.params.id);


        // ตรวจสอบ ID
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


        // ไม่พบ
        if (!result) {

            return res.status(404).json({

                isError: true,

                data: null,

                errorMessage:
                    'ไม่พบ Reservation ที่ต้องการ'

            });

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

// GET RESERVATIONS BY USER

app.get('/api/users/:id/reservations', async (req, res) => {

    try {

        const userId =
            Number(req.params.id);


        // ตรวจสอบ user_id
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


        const result =
            await reservationModel.getReservationsByUserId(
                userId
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

// GET ORDER BY ID

app.get('/api/orders/:id', async (req, res) => {

    try {

        const orderId = Number(req.params.id);

        // ตรวจสอบ order_id
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


        // ไม่พบ Order
        if (!result) {

            return res.status(404).json({

                isError: true,

                data: null,

                errorMessage:
                    'ไม่พบ Order ที่ต้องการ'

            });

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

// START SERVER

app.listen(PORT, () => {

    console.log(
        `Server running at http://localhost:${PORT}`
    );

});