const pool = require('../libs/db_pool');

module.exports = {

    // GET ALL USERS

    getAllUsers: async () => {

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
            `;

            const [rows] = await conn.query(sql);

            return {
                isError: false,
                data: rows,
                errorMessage: ""
            };

        } catch (error) {

            return {
                isError: true,
                data: [],
                errorMessage: error.message
            };

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


    // GET USER BY USERNAME

    getUserByUsername: async (username) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    user_id,
                    username,
                    password,
                    fullname,
                    phone,
                    email,
                    role_id,
                    user_image
                FROM \`user\`
                WHERE username = ?
                LIMIT 1
            `;

            const [rows] = await conn.query(
                sql,
                [username]
            );

            return rows[0] || null;

        } catch (error) {

            console.error(
                'getUserByUsername error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


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

        } catch (error) {

            console.error(
                'getUserById error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


    // CREATE USER

    createUser: async (userData) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                INSERT INTO \`user\`
                (
                    username,
                    password,
                    fullname,
                    phone,
                    email,
                    role_id,
                    user_image
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `;

            const [result] = await conn.query(
                sql,
                [
                    userData.username,
                    userData.password,
                    userData.fullname,
                    userData.phone,
                    userData.email,
                    userData.role_id,
                    userData.user_image
                ]
            );

            return {
                user_id: result.insertId
            };

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


    // UPDATE USER

    // UPDATE USER

updateUser: async (userId, userData) => {

    let conn;

    try {

        conn = await pool.getConnection();

        const sql = `
            UPDATE \`user\`
            SET
                fullname = ?,
                phone = ?,
                email = ?
            WHERE user_id = ?
        `;

        await conn.query(
            sql,
            [
                userData.fullname,
                userData.phone || null,
                userData.email || null,
                userId
            ]
        );

        return {
            isError: false
        };

    } catch (error) {

        console.error(
            'updateUser error:',
            error
        );

        throw error;

    } finally {

        if (conn) {
            conn.release();
        }

    }
},
    

};