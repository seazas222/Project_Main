USE restaurant_db;

-- Existing drinks were stored under the catch-all category before the drink tab existed.
UPDATE `menu`
SET `category` = 'น้ำดื่ม'
WHERE `category` = 'อื่นๆ'
  AND `menu_name` IN ('โค้ก', 'น้ำแดงแฟนต้า', 'สไปร์');
