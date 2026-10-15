-- Run after 20261009_restaurant_features.sql; safe to run more than once.
USE `restaurant_db`;

ALTER TABLE `user`
  ADD COLUMN IF NOT EXISTS `notification_enabled` TINYINT(1) NOT NULL DEFAULT 1;
