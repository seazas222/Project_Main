const pool = require('../libs/db_pool');

module.exports = {

    createOrder: async (orderData) => {

        let conn;

        try {

            conn = await pool.getConnection();
            await conn.beginTransaction();
            const userId = Number(orderData.user_id);
            const reservationId = orderData.reservation_id == null ? null : Number(orderData.reservation_id);

            const [customerRows] = await conn.query(
                'SELECT user_id FROM `user` WHERE user_id = ? AND is_active = 1 AND is_deleted = 0 FOR UPDATE',
                [userId]
            );
            if (!customerRows.length) throw new Error('ไม่พบบัญชีลูกค้าหรือบัญชีถูกระงับ');

            let tableId = orderData.table_id == null ? null : Number(orderData.table_id);

            if (reservationId != null) {
                const [reservationRows] = await conn.query(
                    `SELECT table_id FROM reservation
                     WHERE reservation_id = ? AND user_id = ? AND statusreservation_id IN (1, 4)
                     FOR UPDATE`,
                    [reservationId, userId]
                );
                if (!reservationRows.length) throw new Error('ไม่พบการจองของบัญชีนี้');
                tableId = Number(reservationRows[0].table_id);
            }

            if (reservationId == null) {
                if (!Number.isInteger(tableId) || tableId < 1) throw new Error('กรุณาเลือกโต๊ะสำหรับสั่งอาหารที่ร้าน');
                const [tables] = await conn.query(
                    'SELECT table_id, statustable_id FROM `table` WHERE table_id = ? FOR UPDATE',
                    [tableId]
                );
                if (!tables.length || Number(tables[0].statustable_id) !== 1) throw new Error('โต๊ะนี้ไม่พร้อมให้บริการ');
                const [booking] = await conn.query(
                    `SELECT reservation_id FROM reservation
                     WHERE table_id = ? AND dining_date = CURRENT_DATE()
                       AND TIME(dining_time) <= CURRENT_TIME()
                       AND ADDTIME(TIME(dining_time), '01:00:00') > CURRENT_TIME()
                       AND statusreservation_id IN (1, 4) LIMIT 1`,
                    [tableId]
                );
                if (booking.length) throw new Error('โต๊ะนี้มีรายการจองในช่วงเวลานี้');
                const [activeSessions] = await conn.query(
                    'SELECT session_id, user_id FROM restaurant_table_session WHERE table_id = ? AND ended_at IS NULL LIMIT 1 FOR UPDATE',
                    [tableId]
                );
                if (activeSessions.length && Number(activeSessions[0].user_id) !== userId) throw new Error('โต๊ะนี้กำลังมีลูกค้าใช้บริการอยู่');
                if (!activeSessions.length) {
                    const [unpaidOrders] = await conn.query(
                        `SELECT order_id FROM \`order\`
                         WHERE user_id = ? AND order_status NOT IN ('ชำระแล้ว', 'ยกเลิก')
                         LIMIT 1 FOR UPDATE`,
                        [userId]
                    );
                    if (unpaidOrders.length) throw new Error('ยังมีออร์เดอร์จากโต๊ะเดิมที่รอยืนยันการชำระเงิน กรุณาชำระรายการเดิมก่อนสั่งโต๊ะอื่น');
                    await conn.query('INSERT INTO restaurant_table_session (table_id, user_id) VALUES (?, ?)', [tableId, userId]);
                }
            }

            const sql = `
                INSERT INTO \`order\`
                (
                    user_id,
                    reservation_id,
                    table_id,
                    order_channel
                )
                VALUES (?, ?, ?, ?)
            `;

            const [result] = await conn.query(
                sql,
                [
                    userId,
                    reservationId,
                    tableId,
                    orderData.order_channel || (reservationId == null ? 'walk_in' : 'reservation')
                ]
            );

            await conn.commit();

            return {
                order_id: result.insertId
            };

        } catch (error) {

            if (conn) await conn.rollback();

            console.error(
                'createOrder error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    getOrderById: async (orderId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    order_id,
                    user_id,
                    reservation_id,
                    table_id,
                    order_date,
                    order_status,
                    order_channel,
                    paid_at
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

            console.error(
                'getOrderById error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    getOrdersByUserId: async (userId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    order_id,
                    user_id,
                    reservation_id,
                    table_id,
                    order_date,
                    CASE
                      WHEN o.order_status = 'กำลังทำ'
                       AND NOT EXISTS (
                         SELECT 1 FROM order_detail od
                         WHERE od.order_id = o.order_id AND od.food_status <> 'รอทำ'
                       ) THEN 'รอรับออร์เดอร์'
                      ELSE o.order_status
                    END AS order_status,
                    order_channel,
                    paid_at
                FROM \`order\` o
                WHERE o.user_id = ? AND o.order_status <> 'ยกเลิก'
                ORDER BY o.order_date DESC
            `;

            const [rows] = await conn.query(
                sql,
                [userId]
            );

            return rows;

        } catch (error) {

            console.error(
                'getOrdersByUserId error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },
    updateStatus: async (orderId, status) => {
        const [result] = await pool.query(
            'UPDATE `order` SET order_status = ?, paid_at = IF(? = \'ชำระแล้ว\', CURRENT_TIMESTAMP(), paid_at) WHERE order_id = ?',
            [status, status, orderId]
        );
        return result.affectedRows > 0;
    },

    getAdminOrders: async () => {
        const [rows] = await pool.query(
            `SELECT o.order_id, o.user_id, u.fullname, u.phone, o.reservation_id, o.table_id, t.table_number,
                    o.order_date, o.order_status, o.order_channel, o.paid_at,
                    COALESCE(SUM(od.quantity * od.price), 0) AS total
             FROM \`order\` o
             JOIN \`user\` u ON u.user_id = o.user_id
             LEFT JOIN \`table\` t ON t.table_id = o.table_id
             LEFT JOIN order_detail od ON od.order_id = o.order_id
             GROUP BY o.order_id
             ORDER BY o.order_date DESC`
        );
        return rows;
    }

};
