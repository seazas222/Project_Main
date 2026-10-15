const pool = require('../libs/db_pool');
const { ACTIVE_RESERVATION_STATUSES } = require('../libs/booking_rules');

module.exports = {

    createReservation: async (reservationData) => {

        let conn;

        try {

            conn = await pool.getConnection();
            await conn.beginTransaction();

            // Lock the customer row first so two simultaneous requests for
            // different tables cannot create overlapping bookings.
            const [customerRows] = await conn.query(
                'SELECT user_id FROM `user` WHERE user_id = ? AND is_active = 1 AND is_deleted = 0 FOR UPDATE',
                [reservationData.user_id]
            );
            if (!customerRows.length) throw new Error('ไม่พบบัญชีลูกค้าหรือบัญชีถูกระงับ');

            const [unpaidOrders] = await conn.query(
                `SELECT order_id FROM \`order\`
                 WHERE user_id = ? AND order_status NOT IN ('ชำระแล้ว', 'ยกเลิก')
                 LIMIT 1 FOR UPDATE`,
                [reservationData.user_id]
            );
            if (unpaidOrders.length) {
                throw new Error('ยังมีออร์เดอร์จากโต๊ะเดิมที่รอยืนยันการชำระเงิน กรุณาชำระรายการเดิมก่อนจองโต๊ะใหม่');
            }

            const activeStatuses = ACTIVE_RESERVATION_STATUSES.map(() => '?').join(',');

            const [tableRows] = await conn.query(
                'SELECT table_id, capacity, statustable_id FROM `table` WHERE table_id = ? FOR UPDATE',
                [reservationData.table_id]
            );
            const table = tableRows[0];
            if (!table) throw new Error('ไม่พบโต๊ะที่เลือก');
            if (Number(table.statustable_id) !== 1) throw new Error('โต๊ะนี้ไม่พร้อมให้จอง');
            if (Number(reservationData.guests) > Number(table.capacity)) throw new Error('จำนวนคนเกินความจุของโต๊ะ');

            const [activeSessions] = await conn.query(
                'SELECT session_id FROM restaurant_table_session WHERE table_id = ? AND ended_at IS NULL LIMIT 1',
                [reservationData.table_id]
            );
            if (activeSessions.length) throw new Error('โต๊ะนี้กำลังมีลูกค้าใช้บริการอยู่');

            const statusMarks = activeStatuses;
            const [sameCustomerSlot] = await conn.query(
                `SELECT reservation_id FROM reservation
                 WHERE user_id = ? AND dining_date = ?
                   AND TIME_TO_SEC(dining_time) < TIME_TO_SEC(?) + 3600
                   AND TIME_TO_SEC(dining_time) + 3600 > TIME_TO_SEC(?)
                   AND statusreservation_id IN (${statusMarks}) LIMIT 1`,
                [reservationData.user_id, reservationData.dining_date, reservationData.dining_time, reservationData.dining_time, ...ACTIVE_RESERVATION_STATUSES]
            );
            if (sameCustomerSlot.length) throw new Error('คุณมีรายการจองในช่วงเวลานี้แล้ว');

            const [occupied] = await conn.query(
                `SELECT reservation_id FROM reservation
                 WHERE table_id = ? AND dining_date = ?
                   AND TIME_TO_SEC(dining_time) < TIME_TO_SEC(?) + 3600
                   AND TIME_TO_SEC(dining_time) + 3600 > TIME_TO_SEC(?)
                   AND statusreservation_id IN (${statusMarks}) LIMIT 1`,
                [reservationData.table_id, reservationData.dining_date, reservationData.dining_time, reservationData.dining_time, ...ACTIVE_RESERVATION_STATUSES]
            );
            if (occupied.length) throw new Error('โต๊ะนี้ถูกจองแล้วในช่วงเวลาที่เลือก');

            const sql = `
                INSERT INTO reservation
                (
                    user_id,
                    table_id,
                    booking_date,
                    dining_date,
                    dining_time,
                    guests,
                    statusreservation_id
                )
                VALUES (?, ?, ?, ?, ?, ?, ?)
            `;

            const [result] = await conn.query(sql, [

                reservationData.user_id,

                reservationData.table_id,

                reservationData.booking_date,

                reservationData.dining_date,

                reservationData.dining_time,

                reservationData.guests,

                1

            ]);

            await conn.commit();

            return {
                reservation_id: result.insertId
            };

        } catch (error) {

            if (conn) await conn.rollback();

            console.error(
                'createReservation error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    getAvailableTables: async (diningDate, diningTime, guests) => {
        let conn;
        try {
            conn = await pool.getConnection();
            const statusMarks = ACTIVE_RESERVATION_STATUSES.map(() => '?').join(',');
            const [rows] = await conn.query(
                `SELECT t.table_id, t.table_number, t.capacity, t.statustable_id, ts.statustable_name
                 FROM \`table\` t
                 LEFT JOIN table_status ts ON ts.statustable_id = t.statustable_id
                 WHERE t.statustable_id = 1 AND t.capacity >= ?
                   AND NOT EXISTS (
                     SELECT 1 FROM restaurant_table_session s
                     WHERE s.table_id = t.table_id AND s.ended_at IS NULL
                   )
                   AND NOT EXISTS (
                     SELECT 1 FROM reservation r
                     WHERE r.table_id = t.table_id AND r.dining_date = ?
                       AND TIME_TO_SEC(r.dining_time) < TIME_TO_SEC(?) + 3600
                       AND TIME_TO_SEC(r.dining_time) + 3600 > TIME_TO_SEC(?)
                       AND r.statusreservation_id IN (${statusMarks})
                   )
                 ORDER BY t.table_number ASC`,
                [guests, diningDate, diningTime, diningTime, ...ACTIVE_RESERVATION_STATUSES]
            );
            return rows;
        } finally {
            if (conn) conn.release();
        }
    },

    isRestaurantHoliday: async (date) => {
        const [rows] = await pool.query(
            'SELECT holiday_id, holiday_name FROM restaurant_holiday WHERE holiday_date = ? LIMIT 1',
            [date]
        );
        return rows[0] || null;
    },

    getHolidays: async (fromDate, toDate) => {
        const [rows] = await pool.query(
            'SELECT holiday_id, holiday_date, holiday_name FROM restaurant_holiday WHERE holiday_date BETWEEN ? AND ? ORDER BY holiday_date',
            [fromDate, toDate]
        );
        return rows;
    },

    getReservationById: async (reservationId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT r.reservation_id, r.user_id, r.table_id, r.booking_date,
                       r.dining_date, r.dining_time, r.guests, r.statusreservation_id,
                       rs.statusreservation_name, t.table_number, t.capacity
                FROM reservation r
                LEFT JOIN reservation_status rs ON rs.statusreservation_id = r.statusreservation_id
                LEFT JOIN \`table\` t ON t.table_id = r.table_id
                WHERE r.reservation_id = ?
                LIMIT 1
            `;

            const [rows] = await conn.query(
                sql,
                [reservationId]
            );

            return rows[0] || null;

        } catch (error) {

            console.error(
                'getReservationById error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    getReservationsByUserId: async (userId, { historyOnly = false } = {}) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT r.reservation_id, r.user_id, r.table_id, r.booking_date,
                       r.dining_date, r.dining_time, r.guests, r.statusreservation_id,
                       rs.statusreservation_name, t.table_number, t.capacity
                FROM reservation r
                LEFT JOIN reservation_status rs ON rs.statusreservation_id = r.statusreservation_id
                LEFT JOIN \`table\` t ON t.table_id = r.table_id
                WHERE r.user_id = ? ${historyOnly ? '' : 'AND r.statusreservation_id IN (1, 4)'}
                ORDER BY r.booking_date DESC, r.reservation_id DESC
            `;

            const [rows] = await conn.query(
                sql,
                [userId]
            );

            return rows;

        } catch (error) {

            console.error(
                'getReservationsByUserId error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    updateStatus: async (reservationId, statusId) => {
        const [result] = await pool.query(
            'UPDATE reservation SET statusreservation_id = ? WHERE reservation_id = ?',
            [statusId, reservationId]
        );
        return result.affectedRows > 0;
    },

    cancelForUser: async (reservationId, userId) => {
        const conn = await pool.getConnection();
        try {
            await conn.beginTransaction();
            const [rows] = await conn.query(
                `SELECT reservation_id, table_id, dining_date, dining_time, statusreservation_id
                 FROM reservation WHERE reservation_id = ? AND user_id = ? FOR UPDATE`,
                [reservationId, userId]
            );
            if (!rows.length) throw new Error('ไม่พบรายการจองของคุณ');
            const reservation = rows[0];
            if (![1, 4].includes(Number(reservation.statusreservation_id))) throw new Error('สถานะนี้ยกเลิกไม่ได้');
            const [orders] = await conn.query(
                `SELECT order_id FROM \`order\`
                 WHERE reservation_id = ? AND (order_status IS NULL OR order_status <> 'ยกเลิก')
                 LIMIT 1 FOR UPDATE`,
                [reservationId]
            );
            if (orders.length) throw new Error('การจองนี้มีออร์เดอร์แล้ว กรุณาติดต่อร้านเพื่อดำเนินการ');
            const [sessions] = await conn.query(
                `SELECT session_id FROM restaurant_table_session
                 WHERE table_id = ? AND user_id = ? AND ended_at IS NULL
                 LIMIT 1 FOR UPDATE`,
                [reservation.table_id, userId]
            );
            if (sessions.length) throw new Error('เริ่มใช้โต๊ะแล้ว กรุณาติดต่อร้านเพื่อยกเลิกการจอง');
            await conn.query('UPDATE reservation SET statusreservation_id = 2 WHERE reservation_id = ?', [reservationId]);
            await conn.commit();
            return reservation;
        } catch (error) {
            await conn.rollback();
            throw error;
        } finally {
            conn.release();
        }
    },

    getAdminReservations: async () => {
        const [rows] = await pool.query(
            `SELECT r.reservation_id, r.user_id, u.fullname, u.phone, r.table_id,
                    t.table_number, t.capacity, r.booking_date, r.dining_date,
                    r.dining_time, r.guests, r.statusreservation_id, rs.statusreservation_name
             FROM reservation r JOIN \`user\` u ON u.user_id = r.user_id
             JOIN \`table\` t ON t.table_id = r.table_id
             JOIN reservation_status rs ON rs.statusreservation_id = r.statusreservation_id
             ORDER BY r.dining_date DESC, r.dining_time DESC`
        );
        return rows;
    }

};
