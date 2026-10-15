const bcrypt = require('bcrypt');
const pool = require('../libs/db_pool');

async function main() {
    const username = process.env.ADMIN_USERNAME;
    const password = process.env.ADMIN_PASSWORD;
    const fullname = process.env.ADMIN_FULLNAME || 'Restaurant Admin';
    if (!username || !password || Buffer.byteLength(password, 'utf8') < 8 || Buffer.byteLength(password, 'utf8') > 72) {
        throw new Error('Set ADMIN_USERNAME and ADMIN_PASSWORD (8 to 72 UTF-8 bytes) in my_app/.env first.');
    }
    const [adminRows] = await pool.query('SELECT user_id FROM `user` WHERE role_id = 1 LIMIT 1');
    const [rows] = await pool.query('SELECT user_id FROM `user` WHERE username = ? LIMIT 1', [username]);
    if (adminRows.length && (!rows.length || Number(rows[0].user_id) !== Number(adminRows[0].user_id))) {
        throw new Error('An ADMIN account already exists. This setup command keeps the single-admin rule.');
    }
    const passwordHash = await bcrypt.hash(password, 12);
    if (rows.length) {
        await pool.query('UPDATE `user` SET password = ?, fullname = ?, role_id = 1, is_active = 1 WHERE user_id = ?', [passwordHash, fullname, rows[0].user_id]);
        console.log('Existing account promoted to ADMIN.');
    } else {
        await pool.query('INSERT INTO `user` (username, password, fullname, phone, email, role_id, user_image, is_active) VALUES (?, ?, ?, NULL, NULL, 1, NULL, 1)', [username, passwordHash, fullname]);
        console.log('ADMIN account created.');
    }
}

main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
}).finally(async () => pool.end());
