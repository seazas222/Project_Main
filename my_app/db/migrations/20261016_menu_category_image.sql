USE restaurant_db;

ALTER TABLE `menu`
  ADD COLUMN IF NOT EXISTS `category` VARCHAR(30) NOT NULL DEFAULT 'อื่นๆ' AFTER `price`;

ALTER TABLE `menu`
  ADD COLUMN IF NOT EXISTS `menu_image` VARCHAR(255) NULL AFTER `category`;

UPDATE `menu`
SET `category` = CASE
  WHEN `menu_name` LIKE '%ข้าว%' THEN 'ข้าว'
  WHEN `menu_name` LIKE '%เส้น%' OR `menu_name` LIKE '%ผัดไทย%' OR `menu_name` LIKE '%ก๋วยเตี๋ยว%' THEN 'เส้น'
  ELSE 'อื่นๆ'
END
WHERE `category` = 'อื่นๆ';
