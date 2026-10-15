const pool = require('../libs/db_pool');

module.exports = {

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
                    user_image,
                    is_active,
                    is_deleted
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
                    user_image,
                    is_active,
                    is_deleted
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

    getUserByPhone: async (phone) => {
        const [rows] = await pool.query(
            'SELECT user_id FROM `user` WHERE phone = ? LIMIT 1',
            [phone]
        );
        return rows[0] || null;
    },

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
                    user_image,
                    is_active,
                    is_deleted
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

    updateUser: async (userId, userData) => {

    let conn;

    try {

        conn = await pool.getConnection();

        const sql = `
            UPDATE \`user\`
            SET
                username = ?,
                fullname = ?,
                phone = ?,
                email = ?
            WHERE user_id = ?
        `;

        await conn.query(
            sql,
            [
                userData.username,
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

    updateProfileImage: async (userId, imageName) => {
        const [result] = await pool.query(
            'UPDATE `user` SET user_image = ? WHERE user_id = ?',
            [imageName, userId]
        );
        return result.affectedRows > 0;
    },

setAccountActive: async (userId, isActive) => {
    let conn;
    try {
        conn = await pool.getConnection();
        await conn.query('UPDATE `user` SET is_active = ? WHERE user_id = ?', [isActive ? 1 : 0, userId]);
        return { isError: false };
    } finally {
        if (conn) conn.release();
    }
},

setPasswordHash: async (userId, passwordHash) => {
    const [result] = await pool.query(
        'UPDATE `user` SET password = ? WHERE user_id = ? AND role_id = 2 AND is_deleted = 0',
        [passwordHash, userId]
    );
    return result.affectedRows > 0;
},

deleteCustomerAccount: async ({ userId, archivedUsername, passwordHash }) => {
    const [result] = await pool.query(
        `UPDATE \`user\`
         SET username = ?, password = ?, fullname = 'บัญชีที่ลบแล้ว',
             phone = NULL, email = NULL, is_active = 0, is_deleted = 1
         WHERE user_id = ? AND role_id = 2 AND is_deleted = 0`,
        [archivedUsername, passwordHash, userId]
    );
    return result.affectedRows > 0;
},

};
