-- Adds editable menu composition/details without changing existing menu rows.
USE `restaurant_db`;

ALTER TABLE `menu`
  ADD COLUMN IF NOT EXISTS `description` VARCHAR(1000) NOT NULL DEFAULT '' AFTER `price`;
