const bcrypt = require('bcrypt');
const pool = require('./libs/db_pool');

async function createCustomer() {

    let conn;

    try {

        conn = await pool.getConnection();

        const username = 'customer01';
        const password = '123456';
        const fullname = 'Customer Test';
        const phone = '0812345678';
        const email = 'customer01@gmail.com';
        const roleId = 2;

        const hashedPassword = await bcrypt.hash(password, 10);

        const [existingUser] = await conn.query(
            'SELECT user_id FROM user WHERE username = ?',
            [username]
        );

        if (existingUser.length > 0) {
            console.log('Username นี้มีอยู่แล้ว');
            return;
        }

        const sql = `
            INSERT INTO user
            (
                username,
                password,
                fullname,
                phone,
                email,
                role_id
            )
            VALUES (?, ?, ?, ?, ?, ?)
        `;

        const [result] = await conn.query(sql, [
            username,
            hashedPassword,
            fullname,
            phone,
            email,
            roleId
        ]);

        console.log('สร้าง Customer สำเร็จ');
        console.log('user_id:', result.insertId);
        console.log('username:', username);
        console.log('password:', password);

    } catch (error) {

        console.error('Create customer error:', error);

    } finally {

        if (conn) {
            conn.release();
        }

        await pool.end();
    }
}

createCustomer();
