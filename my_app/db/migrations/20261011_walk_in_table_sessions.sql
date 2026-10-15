-- Walk-in table orders and table session lifecycle.
-- Apply after 20261009_restaurant_features.sql and 20261010_notification_preference.sql.
USE `restaurant_db`;

ALTER TABLE `order`
  ADD COLUMN IF NOT EXISTS `table_id` INT(11) DEFAULT NULL,
  ADD KEY IF NOT EXISTS `idx_order_table` (`table_id`);

CREATE TABLE IF NOT EXISTS `restaurant_table_session` (
  `session_id` INT(11) NOT NULL AUTO_INCREMENT,
  `table_id` INT(11) NOT NULL,
  `user_id` INT(11) NOT NULL,
  `started_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `ended_at` DATETIME DEFAULT NULL,
  PRIMARY KEY (`session_id`),
  KEY `idx_table_session_active` (`table_id`, `ended_at`),
  KEY `idx_table_session_user` (`user_id`, `ended_at`),
  CONSTRAINT `fk_table_session_table` FOREIGN KEY (`table_id`) REFERENCES `table` (`table_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_table_session_user` FOREIGN KEY (`user_id`) REFERENCES `user` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @fk_order_table_exists = (
  SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
  WHERE CONSTRAINT_SCHEMA = DATABASE() AND TABLE_NAME = 'order' AND CONSTRAINT_NAME = 'fk_order_table'
);
SET @sql_add_order_table_fk = IF(@fk_order_table_exists = 0,
  'ALTER TABLE `order` ADD CONSTRAINT `fk_order_table` FOREIGN KEY (`table_id`) REFERENCES `table` (`table_id`) ON DELETE SET NULL ON UPDATE CASCADE',
  'SELECT 1'
);
PREPARE stmt_order_table_fk FROM @sql_add_order_table_fk;
EXECUTE stmt_order_table_fk;
DEALLOCATE PREPARE stmt_order_table_fk;
