-- Stores admin-configurable menu choice groups and the selected option snapshot on each order item.
USE `restaurant_db`;

ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `notification_enabled` TINYINT(1) NOT NULL DEFAULT 1;

ALTER TABLE `menu`
  ADD COLUMN IF NOT EXISTS `option_groups_json` LONGTEXT NULL AFTER `description`;

ALTER TABLE `order_detail`
  ADD COLUMN IF NOT EXISTS `selected_options` LONGTEXT NULL AFTER `food_status`;
