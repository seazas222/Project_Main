const pool = require('../libs/db_pool');

module.exports = {

    // CREATE RESERVATION

    createReservation: async (reservationData) => {

        let conn;

        try {

            conn = await pool.getConnection();

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

                reservationData.statusreservation_id || 1

            ]);

            return {
                reservation_id: result.insertId
            };

        } catch (error) {

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

    // GET RESERVATION BY ID

    getReservationById: async (reservationId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    reservation_id,
                    user_id,
                    table_id,
                    booking_date,
                    dining_date,
                    dining_time,
                    guests,
                    statusreservation_id
                FROM reservation
                WHERE reservation_id = ?
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

    // GET RESERVATIONS BY USER

    getReservationsByUserId: async (userId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    reservation_id,
                    user_id,
                    table_id,
                    booking_date,
                    dining_date,
                    dining_time,
                    guests,
                    statusreservation_id
                FROM reservation
                WHERE user_id = ?
                ORDER BY dining_date DESC, dining_time DESC
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
    }

};