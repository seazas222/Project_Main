const bcrypt = require('bcrypt');
const pool = require('./libs/db_pool');

async function createTestUser() {
    let conn;

    try {
        conn = await pool.getConnection();

        const username = 'customer01';
        const password = '123456';
        const fullname = 'Test Customer';
        const phone = '0812345678';
        const email = 'customer01@gmail.com';

        // เข้ารหัส Password ก่อนเก็บลง Database
        const hashedPassword = await bcrypt.hash(password, 10);

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

        await conn.query(sql, [
            username,
            hashedPassword,
            fullname,
            phone,
            email,
            2
        ]);

        console.log('สร้าง Customer สำเร็จ');
        console.log('Username:', username);
        console.log('Password:', password);

    } catch (error) {
        console.error('สร้าง Customer ไม่สำเร็จ');
        console.error(error.message);

    } finally {
        if (conn) {
            conn.release();
        }

        await pool.end();
    }
}

createTestUser();