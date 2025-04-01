CREATE TABLE IF NOT EXISTS `dalton_vip` (
  `license2` VARCHAR(50) NOT NULL,
  `vip_points` INT NOT NULL DEFAULT 0,
  `vip_level` VARCHAR(50) NOT NULL DEFAULT 'Sin VIP',
  `vip_activated_at` TIMESTAMP NULL DEFAULT NULL,
  `used_referral` BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (`license2`)
);

CREATE TABLE IF NOT EXISTS `dalton_vip_transactions` (
  `id` INT AUTO_INCREMENT NOT NULL,
  `license2` VARCHAR(50) NOT NULL,
  `transaction_id` VARCHAR(100) NOT NULL,
  `points_added` INT NOT NULL,
  `redeemed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `transaction_id` (`transaction_id`),
  KEY `license2` (`license2`)
);
