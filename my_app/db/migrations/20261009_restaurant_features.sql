-- Additive migration for bookings, order workflow, payments and notifications.
-- Back up restaurant_db before applying this migration.

USE `restaurant_db`;

ALTER TABLE `user`
  ADD COLUMN `is_active` TINYINT(1) NOT NULL DEFAULT 1;

ALTER TABLE `reservation`
  ADD KEY `idx_reservation_slot` (`table_id`, `dining_date`, `dining_time`, `statusreservation_id`),
  ADD KEY `idx_reservation_customer_slot` (`user_id`, `dining_date`, `dining_time`);

-- Existing IDs are preserved: 1 = confirmed, 2 = cancelled, 3 = served.
-- New reservations are immediately confirmed when a free table is found.
INSERT INTO `reservation_status` (`statusreservation_id`, `statusreservation_name`)
SELECT 4, 'รอยืนยัน'
WHERE NOT EXISTS (
  SELECT 1 FROM `reservation_status` WHERE `statusreservation_id` = 4
);

UPDATE `reservation_status` SET `statusreservation_name` = 'ยืนยันแล้ว' WHERE `statusreservation_id` = 1;
UPDATE `reservation_status` SET `statusreservation_name` = 'ยกเลิก' WHERE `statusreservation_id` = 2;
UPDATE `reservation_status` SET `statusreservation_name` = 'มาใช้บริการแล้ว' WHERE `statusreservation_id` = 3;

ALTER TABLE `order`
  ADD COLUMN `order_status` VARCHAR(30) NOT NULL DEFAULT 'รอรับออร์เดอร์',
  ADD COLUMN `order_channel` VARCHAR(20) NOT NULL DEFAULT 'walk_in',
  ADD COLUMN `paid_at` DATETIME DEFAULT NULL,
  ADD KEY `idx_order_status_date` (`order_status`, `order_date`);

ALTER TABLE `order_detail`
  ADD COLUMN `food_status` VARCHAR(30) NOT NULL DEFAULT 'รอทำ',
  ADD KEY `idx_order_detail_food_status` (`food_status`);

ALTER TABLE `payment`
  ADD COLUMN `order_id` INT(11) DEFAULT NULL,
  ADD COLUMN `reviewed_by` INT(11) DEFAULT NULL,
  ADD COLUMN `reviewed_at` DATETIME DEFAULT NULL,
  ADD COLUMN `payment_reference` VARCHAR(100) DEFAULT NULL,
  ADD KEY `idx_payment_order` (`order_id`),
  ADD KEY `idx_payment_status` (`payment_status_id`),
  ADD CONSTRAINT `fk_payment_order` FOREIGN KEY (`order_id`) REFERENCES `order` (`order_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `fk_payment_reviewer` FOREIGN KEY (`reviewed_by`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE;

INSERT INTO `payment_status` (`payment_status_id`, `payment_status_name`)
SELECT 3, 'รอตรวจสอบ'
WHERE NOT EXISTS (
  SELECT 1 FROM `payment_status` WHERE `payment_status_id` = 3
);

CREATE TABLE IF NOT EXISTS `restaurant_holiday` (
  `holiday_id` INT(11) NOT NULL AUTO_INCREMENT,
  `holiday_date` DATE NOT NULL,
  `holiday_name` VARCHAR(150) NOT NULL,
  `created_by` INT(11) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`holiday_id`),
  UNIQUE KEY `uq_restaurant_holiday_date` (`holiday_date`),
  CONSTRAINT `fk_restaurant_holiday_admin` FOREIGN KEY (`created_by`) REFERENCES `user` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `push_device` (
  `push_device_id` INT(11) NOT NULL AUTO_INCREMENT,
  `user_id` INT(11) NOT NULL,
  `fcm_token` VARCHAR(512) NOT NULL,
  `platform` VARCHAR(20) DEFAULT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP() ON UPDATE CURRENT_TIMESTAMP(),
  PRIMARY KEY (`push_device_id`),
  UNIQUE KEY `uq_push_device_token` (`fcm_token`),
  KEY `idx_push_device_user` (`user_id`),
  CONSTRAINT `fk_push_device_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `customer_notification` (
  `notification_id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `user_id` INT(11) NOT NULL,
  `notification_type` VARCHAR(40) NOT NULL,
  `title` VARCHAR(150) NOT NULL,
  `body` VARCHAR(500) NOT NULL,
  `related_id` INT(11) DEFAULT NULL,
  `is_read` TINYINT(1) NOT NULL DEFAULT 0,
  `sent_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`notification_id`),
  KEY `idx_notification_user_date` (`user_id`, `sent_at`),
  CONSTRAINT `fk_notification_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- The daily reminder worker records a delivery key to avoid duplicate alerts.
CREATE TABLE IF NOT EXISTS `notification_delivery` (
  `delivery_id` BIGINT(20) NOT NULL AUTO_INCREMENT,
  `notification_key` VARCHAR(120) NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (`delivery_id`),
  UNIQUE KEY `uq_notification_delivery_key` (`notification_key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
