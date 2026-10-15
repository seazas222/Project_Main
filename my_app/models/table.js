const pool = require('../libs/db_pool');

module.exports = {

    getAllTables: async () => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    t.table_id,
                    t.table_number,
                    t.capacity,
                    t.statustable_id,
                    ts.statustable_name,
                    EXISTS(SELECT 1 FROM restaurant_table_session s WHERE s.table_id = t.table_id AND s.ended_at IS NULL) AS is_occupied
                FROM \`table\` t
                LEFT JOIN table_status ts
                    ON t.statustable_id = ts.statustable_id
                ORDER BY t.table_number ASC
            `;

            const [rows] = await conn.query(sql);

            return {
                isError: false,
                data: rows,
                errorMessage: ""
            };

        } catch (error) {

            console.error(
                'getAllTables error:',
                error
            );

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },

    getWalkInTables: async (userId) => {
        const [rows] = await pool.query(
            `SELECT t.table_id, t.table_number, t.capacity, t.statustable_id, ts.statustable_name
             FROM \`table\` t
             LEFT JOIN table_status ts ON ts.statustable_id = t.statustable_id
             WHERE t.statustable_id = 1
               AND NOT EXISTS (
                 SELECT 1 FROM restaurant_table_session s
                 WHERE s.table_id = t.table_id AND s.ended_at IS NULL AND s.user_id <> ?
               )
               AND NOT EXISTS (
                 SELECT 1 FROM reservation r
                 WHERE r.table_id = t.table_id AND r.dining_date = CURRENT_DATE()
                   AND TIME(r.dining_time) <= CURRENT_TIME()
                   AND ADDTIME(TIME(r.dining_time), '01:00:00') > CURRENT_TIME()
                   AND r.statusreservation_id IN (1, 4)
               )
             ORDER BY t.table_number ASC`,
            [Number(userId)]
        );
        return rows;
    },

    clearWalkInSession: async (tableId) => {
        const [result] = await pool.query(
            'UPDATE restaurant_table_session SET ended_at = CURRENT_TIMESTAMP() WHERE table_id = ? AND ended_at IS NULL',
            [Number(tableId)]
        );
        return result.affectedRows > 0;
    },

    updateTable: async (tableId, { table_number, capacity, statustable_id }) => {
        const [result] = await pool.query(
            'UPDATE `table` SET table_number = ?, capacity = ?, statustable_id = ? WHERE table_id = ?',
            [table_number, capacity, statustable_id, tableId]
        );
        return result.affectedRows > 0;
    },

    createTable: async ({ table_number, capacity, statustable_id = 1 }) => {
        const [result] = await pool.query(
            'INSERT INTO `table` (table_number, capacity, statustable_id) VALUES (?, ?, ?)',
            [table_number, capacity, statustable_id]
        );
        return result.insertId;
    }

};
