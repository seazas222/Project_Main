'use strict';

const fs = require('node:fs/promises');
const path = require('node:path');
const pool = require('../libs/db_pool');

// Asset names are stable so the Flutter bundle can also show the right photo
// when an uploaded image is temporarily unavailable.
const photoByMenuName = new Map([
    ['ข้าวผัด', '1'],
    ['ข้าวผัดกะเพรา', '2'],
    ['ข้าวเครื่องแกง', '3'],
    ['ผัดซีอิ๊ว', '4'],
    ['ข้าวไข่เจียว', '6'],
    ['ข้าวผัดคะน้า', '14'],
    ['ข้าวผัดกระเทียม', '15'],
    ['ข้าวผัดผักรวมมิตร', '18'],
    ['สุกี้แห้ง', '26'],
    ['ก๋วยเตี๋ยวคั่ว', '28'],
    ['ไข่ดาว', '31'],
    ['ไข่เจียว', '32'],
    ['ก๋วยเตี๋ยว', '33'],
    ['ก๋วยเตี๋ยวน้ำ', '33'],
    ['เกาเหลา', '34'],
    ['โค้ก', '35'],
    ['น้ำแดง', '36'],
    ['สไปร์', '37'],
]);

const incorrectPhotoNames = new Set([
    'menu-162f81f7-4c64-4992-a38c-e3d46eb09842.jpg',
]);

async function main() {
    const sourceDirectory = path.resolve(__dirname, '../../flutter_application_1/assets/menu');
    const imageDirectory = path.resolve(__dirname, '../storage/menu_images');
    const backupDirectory = path.resolve(__dirname, '../storage/menu_catalog_backups');
    const connection = await pool.getConnection();
    let transaction = false;
    try {
        const [rows] = await connection.query(
            'SELECT menu_id, menu_name, menu_image FROM menu WHERE statusmenu_id = 1 ORDER BY menu_id'
        );
        const missing = rows.filter(row => !photoByMenuName.has(row.menu_name));
        if (missing.length) {
            throw new Error(`ยังไม่มีภาพของเมนู: ${missing.map(row => row.menu_name).join(', ')}`);
        }

        await fs.mkdir(imageDirectory, { recursive: true });
        await fs.mkdir(backupDirectory, { recursive: true });
        const backupPath = path.join(backupDirectory, `menu-photo-links-${new Date().toISOString().replace(/[:.]/g, '-')}.json`);
        await fs.writeFile(backupPath, JSON.stringify(rows, null, 2), 'utf8');

        for (const sourceId of new Set(photoByMenuName.values())) {
            const source = path.join(sourceDirectory, `menu_${sourceId}.png`);
            const target = path.join(imageDirectory, `menu-${sourceId.padStart(8, '0')}.png`);
            await fs.copyFile(source, target);
        }

        await connection.beginTransaction();
        transaction = true;
        let changed = 0;
        let preserved = 0;
        for (const row of rows) {
            const photoId = photoByMenuName.get(row.menu_name);
            const filename = `menu-${photoId.padStart(8, '0')}.png`;
            if (row.menu_image && row.menu_image !== filename && !incorrectPhotoNames.has(row.menu_image)) {
                preserved++;
                continue;
            }
            if (row.menu_image !== filename) {
                await connection.query('UPDATE menu SET menu_image = ? WHERE menu_id = ?', [filename, row.menu_id]);
                changed++;
            }
        }
        await connection.commit();
        transaction = false;
        console.log(`ผูกภาพอาหารใหม่ ${changed} เมนู; ภาพที่แอดมินตั้งไว้และไม่อยู่ในรายการผิด ${preserved} เมนู`);
        console.log(`สำรองการอ้างอิงภาพเดิม: ${backupPath}`);
    } catch (error) {
        if (transaction) await connection.rollback().catch(() => {});
        throw error;
    } finally {
        connection.release();
    }
}

main().catch(error => {
    console.error('ติดตั้งภาพเมนูไม่สำเร็จ:', error.message);
    process.exitCode = 1;
}).finally(() => pool.end());
