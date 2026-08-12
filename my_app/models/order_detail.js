const pool = require('../libs/db_pool');

module.exports = {

    // =========================
    // CREATE ORDER DETAIL
    // =========================

    createOrderDetail: async (detailData) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                INSERT INTO order_detail
                (
                    order_id,
                    menu_id,
                    quantity,
                    price,
                    spicy_id,
                    serving_id,
                    rice_id,
                    egg_id,
                    note
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            `;

            const [result] = await conn.query(sql, [

                detailData.order_id,

                detailData.menu_id,

                detailData.quantity,

                detailData.price,

                detailData.spicy_id || null,

                detailData.serving_id || null,

                detailData.rice_id || null,

                detailData.egg_id || null,

                detailData.note || null

            ]);

            return {
                orderdetail_id: result.insertId
            };

        } catch (error) {

            console.error(
                'createOrderDetail error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    // GET ORDER DETAIL

    getOrderDetails: async (orderId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    orderdetail_id,
                    order_id,
                    menu_id,
                    quantity,
                    price,
                    spicy_id,
                    serving_id,
                    rice_id,
                    egg_id,
                    note
                FROM order_detail
                WHERE order_id = ?
                ORDER BY orderdetail_id ASC
            `;

            const [rows] = await conn.query(
                sql,
                [orderId]
            );

            return rows;

        } catch (error) {

            console.error(
                'getOrderDetails error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    // GET ORDER DETAILS BY ORDER ID

    getOrderDetailsByOrderId: async (orderId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
            SELECT
                od.orderdetail_id,
                od.order_id,
                od.menu_id,
                m.menu_name,
                od.quantity,
                od.price,
                od.spicy_id,
                od.serving_id,
                od.rice_id,
                od.egg_id,
                od.note
            FROM order_detail AS od
            INNER JOIN menu AS m
                ON od.menu_id = m.menu_id
            WHERE od.order_id = ?
            ORDER BY od.orderdetail_id ASC
        `;

            const [rows] = await conn.query(
                sql,
                [orderId]
            );

            return rows;

        } catch (error) {

            console.error(
                'getOrderDetailsByOrderId error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    }

};