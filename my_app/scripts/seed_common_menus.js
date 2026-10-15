'use strict';

const fs = require('node:fs/promises');
const path = require('node:path');
const pool = require('../libs/db_pool');

// ราคาใน menu ไม่รวมเนื้อ จึงคิดราคาเนื้อทุกชนิดที่เลือกเพิ่มอีกครั้ง
const proteinOptions = [
    { id: 'protein-pork', name: 'หมู', extra_price: 20, available: true },
    { id: 'protein-minced-pork', name: 'หมูสับ', extra_price: 20, available: true },
    { id: 'protein-chicken', name: 'ไก่', extra_price: 20, available: true },
    { id: 'protein-crispy-pork', name: 'หมูกรอบ', extra_price: 35, available: true },
    { id: 'protein-shrimp', name: 'กุ้ง', extra_price: 35, available: true },
    { id: 'protein-seafood', name: 'ทะเล', extra_price: 40, available: true },
];

const catalog = [
    { name: 'ข้าวผัด', aliases: ['ข้าวผัดหมู', 'ข้าวผัดไก่', 'ข้าวผัดกุ้ง'], category: 'ข้าว', price: 30 },
    { name: 'ข้าวผัดกะเพรา', aliases: ['ข้าวกะเพรา', 'กะเพราหมูสับราดข้าว', 'กะเพราไก่ราดข้าว', 'กะเพราหมูกรอบราดข้าว', 'กะเพราทะเลราดข้าว'], category: 'ข้าว', price: 30, spicy: true },
    { name: 'ข้าวเครื่องแกง', aliases: ['พริกแกงหมูราดข้าว'], category: 'ข้าว', price: 30, spicy: true },
    { name: 'ข้าวผัดคะน้า', aliases: ['คะน้าหมูกรอบราดข้าว'], category: 'ข้าว', price: 30 },
    { name: 'ข้าวผัดกระเทียม', aliases: ['หมูกระเทียมราดข้าว', 'ไก่กระเทียมราดข้าว'], category: 'ข้าว', price: 35 },
    { name: 'ข้าวผัดผักรวมมิตร', aliases: ['ผัดผักรวมมิตรราดข้าว'], category: 'ข้าว', price: 30 },
    { name: 'ข้าวไข่เจียว', aliases: ['ข้าวไข่เจียวหมูสับ'], category: 'ข้าว', price: 25, egg: false },
    { name: 'ผัดซีอิ๊ว', aliases: ['ผัดซีอิ๊วหมู', 'ผัดซีอิ๊วไก่'], category: 'เส้น', price: 35 },
    { name: 'สุกี้แห้ง', aliases: ['สุกี้แห้งไก่'], category: 'เส้น', price: 35, egg: false },
    { name: 'ก๋วยเตี๋ยวคั่ว', aliases: ['ก๋วยเตี๋ยวคั่วไก่'], category: 'เส้น', price: 40 },
    { name: 'ก๋วยเตี๋ยวน้ำ', aliases: [], category: 'เส้น', price: 30, egg: false },
    { name: 'เกาเหลา', aliases: [], category: 'เส้น', price: 35, egg: false },
];

const disallowedName = /ข้าวต้ม|ต้มยำ|ต้มจืด|สุกี้น้ำ|ราดหน้า|ผัดไทย/;
const normalizeName = value => String(value).trim().normalize('NFC').toLocaleLowerCase('th');

function makeProteinGroup() {
    return {
        id: 'protein', name: 'เนื้อ', required: true, max_select: 5,
        options: proteinOptions.map(option => ({ ...option })),
    };
}

function defaultGroups(item) {
    const groups = [];
    if (item.spicy) groups.push({
        id: 'spicy', name: 'ระดับความเผ็ด', required: true, max_select: 1,
        options: [
            { id: 'spicy-1', name: 'ไม่เผ็ด', extra_price: 0, available: true },
            { id: 'spicy-2', name: 'เผ็ดกลาง', extra_price: 0, available: true },
            { id: 'spicy-3', name: 'เผ็ดมาก', extra_price: 0, available: true },
        ],
    });
    groups.push({
        id: 'size', name: 'ขนาด', required: true, max_select: 1,
        options: [
            { id: 'size-1', name: 'ธรรมดา', extra_price: 0, available: true },
            { id: 'size-2', name: 'พิเศษ', extra_price: 10, available: true },
        ],
    });
    if (item.egg !== false) groups.push({
        id: 'egg', name: 'ไข่', required: false, max_select: 1,
        options: [
            { id: 'egg-1', name: 'ไข่ดาว', extra_price: 10, available: true },
            { id: 'egg-2', name: 'ไข่เจียว', extra_price: 15, available: true },
        ],
    });
    groups.push({
        id: 'serving', name: 'รูปแบบการรับอาหาร', required: true, max_select: 1,
        options: [
            { id: 'serving-1', name: 'ทานที่ร้าน', extra_price: 0, available: true },
            { id: 'serving-2', name: 'กลับบ้าน', extra_price: 0, available: true },
        ],
    });
    return groups;
}

function groupsFor(item, existingRow) {
    let groups;
    try { groups = JSON.parse(existingRow?.option_groups_json || '[]'); }
    catch (_) { groups = []; }
    if (!Array.isArray(groups) || groups.length === 0) groups = defaultGroups(item);
    groups = groups.filter(group => group && group.id !== 'protein' && group.name !== 'เนื้อ' && (item.egg !== false || group.id !== 'egg'));
    groups.push(makeProteinGroup());
    return groups;
}

async function backup(rows) {
    const directory = path.join(__dirname, '../storage/menu_catalog_backups');
    await fs.mkdir(directory, { recursive: true });
    const filename = `before-a-la-carte-v2-${new Date().toISOString().replace(/[:.]/g, '-')}.json`;
    const fullPath = path.join(directory, filename);
    await fs.writeFile(fullPath, JSON.stringify(rows, null, 2), 'utf8');
    return fullPath;
}

async function main() {
    let connection;
    let locked = false;
    let inTransaction = false;
    try {
        connection = await pool.getConnection();
        const [[lock]] = await connection.query('SELECT GET_LOCK(?, 10) AS acquired', ['seed_common_menus_v2']);
        if (Number(lock.acquired) !== 1) throw new Error('มีการแก้ไขชุดเมนูอีกครั้งอยู่ กรุณาลองใหม่');
        locked = true;

        await connection.query(`CREATE TABLE IF NOT EXISTS menu_catalog_seed (
            seed_key VARCHAR(100) NOT NULL PRIMARY KEY,
            applied_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci`);
        const [[applied]] = await connection.query('SELECT seed_key FROM menu_catalog_seed WHERE seed_key = ?', ['a_la_carte_v2']);
        if (applied) {
            console.log('ชุดเมนูอาหารตามสั่งเวอร์ชัน 2 ถูกนำเข้าแล้ว ไม่มีการเปลี่ยนข้อมูลซ้ำ');
            return;
        }

        const [rows] = await connection.query(`SELECT m.menu_id, m.menu_name, m.price, m.description, m.category,
            m.menu_image, m.option_groups_json, m.statusmenu_id,
            (SELECT COUNT(*) FROM order_detail od WHERE od.menu_id = m.menu_id) AS order_refs
            FROM menu m ORDER BY m.menu_id`);
        const backupPath = await backup(rows);
        console.log(`สำรองข้อมูลเมนูก่อนแก้ไว้ที่ ${backupPath}`);

        const claimed = new Set();
        const removals = new Set();
        const changes = { created: [], updated: [], removed: [], hidden: [] };
        await connection.beginTransaction();
        inTransaction = true;

        for (const item of catalog) {
            const names = new Set([item.name, ...item.aliases].map(normalizeName));
            const candidates = rows.filter(row => names.has(normalizeName(row.menu_name)));
            const survivor = candidates.find(row => normalizeName(row.menu_name) === normalizeName(item.name)) || candidates[0];
            const optionGroups = JSON.stringify(groupsFor(item, survivor));
            if (survivor) {
                claimed.add(Number(survivor.menu_id));
                await connection.query('UPDATE menu SET menu_name = ?, price = ?, category = ?, option_groups_json = ?, statusmenu_id = 1 WHERE menu_id = ?',
                    [item.name, item.price, item.category, optionGroups, survivor.menu_id]);
                changes.updated.push(`${survivor.menu_id}: ${item.name}`);
            } else {
                const [result] = await connection.query('INSERT INTO menu (menu_name, price, category, menu_image, option_groups_json, statusmenu_id) VALUES (?, ?, ?, NULL, ?, 1)',
                    [item.name, item.price, item.category, optionGroups]);
                changes.created.push(`${result.insertId}: ${item.name}`);
            }
            for (const row of candidates) if (Number(row.menu_id) !== Number(survivor?.menu_id)) removals.add(Number(row.menu_id));
        }

        for (const row of rows) {
            const id = Number(row.menu_id);
            if (claimed.has(id) || removals.has(id)) continue;
            if (disallowedName.test(row.menu_name)) removals.add(id);
            else if (row.category === 'ข้าว' && Number(row.statusmenu_id) === 1) {
                throw new Error(`พบเมนูข้าวที่ยังไม่ได้กำหนดวิธีรวม: ${row.menu_name} (#${id})`);
            }
        }

        for (const id of removals) {
            const row = rows.find(item => Number(item.menu_id) === id);
            if (Number(row.order_refs) > 0) {
                await connection.query('UPDATE menu SET statusmenu_id = 2 WHERE menu_id = ?', [id]);
                changes.hidden.push(`${id}: ${row.menu_name}`);
            } else {
                await connection.query('DELETE FROM menu WHERE menu_id = ?', [id]);
                changes.removed.push(`${id}: ${row.menu_name}`);
            }
        }

        await connection.query('INSERT INTO menu_catalog_seed (seed_key) VALUES (?)', ['a_la_carte_v2']);
        await connection.commit();
        inTransaction = false;
        for (const [kind, entries] of Object.entries(changes)) {
            console.log(`${kind}: ${entries.length}`);
            for (const entry of entries) console.log(`- ${entry}`);
        }
        console.log('เมนูข้าวทุกจานมีหัวข้อ เนื้อ (ต้องเลือก, สูงสุด 5 ชนิด) และคิดราคาเนื้อแต่ละชนิดแยกจากราคาจานพื้นฐาน');
    } catch (error) {
        if (inTransaction && connection) await connection.rollback().catch(() => {});
        throw error;
    } finally {
        if (connection) {
            if (locked) await connection.query('SELECT RELEASE_LOCK(?)', ['seed_common_menus_v2']).catch(() => {});
            connection.release();
        }
    }
}

main().catch(error => {
    console.error('ปรับเมนูอาหารไม่สำเร็จ:', error.message);
    process.exitCode = 1;
}).finally(async () => pool.end());
