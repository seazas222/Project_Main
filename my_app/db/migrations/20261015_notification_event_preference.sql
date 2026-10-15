-- Keep the notification preference that was active when each event was created.
USE `restaurant_db`;

ALTER TABLE `customer_notification`
  ADD COLUMN IF NOT EXISTS `notifications_enabled` TINYINT(1) NOT NULL DEFAULT 1 AFTER `is_read`;
