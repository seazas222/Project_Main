const pool = require('../libs/db_pool');

module.exports = {

    createOrderDetail: async (detailData) => {

        let conn;

        try {

            conn = await pool.getConnection();
            await conn.beginTransaction();

            const [orders] = await conn.query(
                'SELECT order_status FROM `order` WHERE order_id = ? FOR UPDATE',
                [Number(detailData.order_id)]
            );
            if (!orders.length) throw new Error('ไม่พบออร์เดอร์');
            if (!['รอรับออร์เดอร์', 'รอทำ'].includes(orders[0].order_status)) {
                throw new Error('ออร์เดอร์นี้ส่งรายการเพิ่มไม่ได้แล้ว');
            }

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
                    note,
                    selected_options
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            `;

            const spicyId =
                detailData.spicy_id == null
                    ? null
                    : Number(detailData.spicy_id);

            const servingId =
                detailData.serving_id == null
                    ? null
                    : Number(detailData.serving_id);

            const riceId =
                detailData.rice_id == null
                    ? null
                    : Number(detailData.rice_id);

            const eggId =
                detailData.egg_id == null
                    ? null
                    : Number(detailData.egg_id);

            const [result] = await conn.query(
                sql,
                [
                    Number(detailData.order_id),
                    Number(detailData.menu_id),
                    Number(detailData.quantity),
                    Number(detailData.price),
                    spicyId,
                    servingId,
                    riceId,
                    eggId,
                    detailData.note ?? null,
                    detailData.selected_options ?? null
                ]
            );

            await conn.commit();

            return {
                orderdetail_id: result.insertId
            };

        } catch (error) {

            if (conn) await conn.rollback();

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
                    m.price AS menu_price,
                    od.quantity,
                    od.price,
                    od.spicy_id,
                    od.serving_id,
                    od.rice_id,
                    od.egg_id,
                    od.note,
                    od.food_status,
                    od.selected_options
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
    },

    updateFoodStatus: async (detailId, status) => {
        const [result] = await pool.query(
            'UPDATE order_detail SET food_status = ? WHERE orderdetail_id = ?',
            [status, detailId]
        );
        return result.affectedRows > 0;
    },

    getAdminOrderDetails: async () => {
        const [rows] = await pool.query(
            `SELECT od.orderdetail_id, od.order_id, od.menu_id, m.menu_name,
                    od.quantity, od.price, od.food_status, od.note, od.selected_options,
                    od.spicy_id, od.serving_id, od.rice_id, od.egg_id,
                    o.order_channel, o.order_status, o.order_date, o.table_id, t.table_number
             FROM order_detail od
             JOIN menu m ON m.menu_id = od.menu_id
             JOIN \`order\` o ON o.order_id = od.order_id
             LEFT JOIN \`table\` t ON t.table_id = o.table_id
             WHERE o.order_status NOT IN ('ยกเลิก', 'ชำระแล้ว')
             ORDER BY od.order_id DESC, od.orderdetail_id ASC`
        );
        return rows;
    }

};
