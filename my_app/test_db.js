const pool = require('./libs/db_pool');

async function testDatabase() {

    let conn;

    try {

        conn = await pool.getConnection();

        console.log('เชื่อมต่อ MariaDB สำเร็จ!');

        const [rows] = await conn.query(
            'SELECT DATABASE() AS database_name'
        );

        console.log('Database:', rows[0].database_name);

    } catch (error) {

        console.error('เชื่อมต่อ Database ไม่สำเร็จ');
        console.error(error);

    } finally {

        if (conn) {
            conn.release();
        }

        await pool.end();
    }
}

testDatabase();