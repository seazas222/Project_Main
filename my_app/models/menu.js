const pool = require('../libs/db_pool');

module.exports = {

    // =========================
    // GET ALL MENU
    // =========================

    getAllMenu: async () => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    menu_id,
                    menu_name,
                    price,
                    statusmenu_id
                FROM MENU
                ORDER BY menu_id ASC
            `;

            const [rows] = await conn.query(sql);

            return {
                isError: false,
                data: rows,
                errorMessage: ""
            };

        } catch (error) {

            console.error('getAllMenu error:', error);

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    },


    // =========================
    // GET MENU BY ID
    // =========================

    getMenuById: async (menuId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    menu_id,
                    menu_name,
                    price,
                    statusmenu_id
                FROM MENU
                WHERE menu_id = ?
                LIMIT 1
            `;

            const [rows] = await conn.query(
                sql,
                [menuId]
            );

            return rows[0] || null;

        } catch (error) {

            console.error('getMenuById error:', error);

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    }

};