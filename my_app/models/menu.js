const pool = require('../libs/db_pool');

const DEFAULT_OPTION_GROUPS = [
    { id: 'spicy', name: 'ระดับความเผ็ด', required: true, max_select: 1, options: [
        { id: 'spicy-1', name: 'ไม่เผ็ด', extra_price: 0 }, { id: 'spicy-2', name: 'เผ็ดกลาง', extra_price: 0 }, { id: 'spicy-3', name: 'เผ็ดมาก', extra_price: 0 }
    ] },
    { id: 'size', name: 'เลือกขนาด', required: true, max_select: 1, options: [
        { id: 'size-1', name: 'ธรรมดา', extra_price: 0 }, { id: 'size-2', name: 'พิเศษ', extra_price: 10 }, { id: 'size-3', name: 'พิเศษมาก', extra_price: 20 }
    ] },
    { id: 'egg', name: 'ไข่', required: true, max_select: 1, options: [
        { id: 'egg-1', name: 'ไม่เพิ่ม', extra_price: 0 }, { id: 'egg-2', name: 'ไข่ดาว', extra_price: 10 }, { id: 'egg-3', name: 'ไข่เจียว', extra_price: 15 }
    ] },
    { id: 'serving', name: 'รูปแบบการรับอาหาร', required: true, max_select: 1, options: [
        { id: 'serving-1', name: 'ทานที่ร้าน', extra_price: 0 }, { id: 'serving-2', name: 'กลับบ้าน', extra_price: 0 }
    ] }
];

function parseGroups(raw) {
    if (raw == null) return DEFAULT_OPTION_GROUPS;
    try {
        const parsed = typeof raw === 'string' ? JSON.parse(raw) : raw;
        return Array.isArray(parsed) ? parsed : [];
    } catch (_) {
        return [];
    }
}

function withParsedGroups(rows) {
    return rows.map((row) => ({ ...row, option_groups: parseGroups(row.option_groups_json) }));
}

module.exports = {

    getAllMenu: async ({ availableOnly = false } = {}) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    menu_id,
                    menu_name,
                    price,
                    description,
                    category,
                    menu_image,
                    option_groups_json,
                    statusmenu_id
                FROM MENU
                ${availableOnly ? 'WHERE statusmenu_id = 1' : ''}
                ORDER BY menu_id ASC
            `;

            const [rows] = await conn.query(sql);

            return {
                isError: false,
                data: withParsedGroups(rows),
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

    getMenuById: async (menuId) => {

        let conn;

        try {

            conn = await pool.getConnection();

            const sql = `
                SELECT
                    menu_id,
                    menu_name,
                    price,
                    description,
                    category,
                    menu_image,
                    option_groups_json,
                    statusmenu_id
                FROM MENU
                WHERE menu_id = ? AND statusmenu_id = 1
                LIMIT 1
            `;

            const [rows] = await conn.query(
                sql,
                [menuId]
            );

            return rows[0] ? withParsedGroups(rows)[0] : null;

        } catch (error) {

            console.error('getMenuById error:', error);

            throw error;

        } finally {

            if (conn) {
                conn.release();
            }

        }
    }

    ,
    createMenu: async ({ menu_name, price, category = 'อื่นๆ', menu_image = null, option_groups = DEFAULT_OPTION_GROUPS, statusmenu_id = 1 }) => {
        const [result] = await pool.query(
            'INSERT INTO menu (menu_name, price, category, menu_image, option_groups_json, statusmenu_id) VALUES (?, ?, ?, ?, ?, ?)',
            [menu_name, price, category, menu_image, JSON.stringify(option_groups), statusmenu_id]
        );
        return result.insertId;
    },

    updateMenu: async (menuId, { menu_name, price, category = 'อื่นๆ', menu_image, option_groups = DEFAULT_OPTION_GROUPS, statusmenu_id }) => {
        const [result] = await pool.query(
            'UPDATE menu SET menu_name = ?, price = ?, category = ?, menu_image = COALESCE(?, menu_image), option_groups_json = ?, statusmenu_id = ? WHERE menu_id = ?',
            [menu_name, price, category, menu_image ?? null, JSON.stringify(option_groups), statusmenu_id, menuId]
        );
        return result.affectedRows > 0;
    },

    deleteMenu: async (menuId) => {
        const [result] = await pool.query('DELETE FROM menu WHERE menu_id = ?', [menuId]);
        return result.affectedRows > 0;
    }

};
