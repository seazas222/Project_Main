-- Supports account removal while preserving historical reservations and orders.
USE `restaurant_db`;

ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `is_deleted` TINYINT(1) NOT NULL DEFAULT 0 AFTER `is_active`;
