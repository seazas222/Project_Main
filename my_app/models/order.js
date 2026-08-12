const pool = require('../libs/db_pool');

module.exports = {

    // =========================
    // CREATE ORDER
    // =========================

    createOrder: async (orderData) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                INSERT INTO \`order\`
                (
                    user_id,
                    reservation_id
                )
                VALUES (?, ?)
            `;

            const [result] = await conn.query(sql, [

                orderData.user_id,

                orderData.reservation_id || null

            ]);

            return {
                order_id: result.insertId
            };

        } catch (error) {

            console.error('createOrder error:', error);

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


    // =========================
    // GET ORDER BY ID
    // =========================

    getOrderById: async (orderId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    order_id,
                    user_id,
                    reservation_id,
                    order_date
                FROM \`order\`
                WHERE order_id = ?
                LIMIT 1
            `;

            const [rows] = await conn.query(
                sql,
                [orderId]
            );

            return rows[0] || null;

        } catch (error) {

            console.error('getOrderById error:', error);

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


    // =========================
    // GET ORDERS BY USER
    // =========================

    getOrdersByUserId: async (userId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    order_id,
                    user_id,
                    reservation_id,
                    order_date
                FROM \`order\`
                WHERE user_id = ?
                ORDER BY order_date DESC
            `;

            const [rows] = await conn.query(
                sql,
                [userId]
            );

            return rows;

        } catch (error) {

            console.error('getOrdersByUserId error:', error);

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    }

};