DROP TABLE IF EXISTS `booking_services`;
DROP TABLE IF EXISTS `booking_payments`;
DROP TABLE IF EXISTS `pitch_reviews`;
DROP TABLE IF EXISTS `league_announcement_comments`;
DROP TABLE IF EXISTS `league_announcements`;
DROP TABLE IF EXISTS `bookings`;
DROP TABLE IF EXISTS `services`;
DROP TABLE IF EXISTS `price_rules`;
DROP TABLE IF EXISTS `pitches`;
DROP TABLE IF EXISTS `matches`;
DROP TABLE IF EXISTS `league_registrations`;
DROP TABLE IF EXISTS `leagues`;
DROP TABLE IF EXISTS `venues`;
DROP TABLE IF EXISTS `team_members`;
DROP TABLE IF EXISTS `teams`;
DROP TABLE IF EXISTS `password_reset_tokens`;
DROP TABLE IF EXISTS `users`;
DROP TABLE IF EXISTS `time_slots`;

-- 1. Tạo bảng users trước (Đổi id thành BIGINT để đồng bộ toàn hệ thống)
CREATE TABLE IF NOT EXISTS `users` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `username` VARCHAR(255) NOT NULL,
    `email` VARCHAR(255) UNIQUE,
    `password` VARCHAR(255),
    `role` VARCHAR(255),
    `created_at` DATETIME,
    `team_id` BIGINT,
    `phone_number` VARCHAR(20),
    `avatar_url` VARCHAR(255),
    `membership_points` INT NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
);

-- 2. Tạo bảng teams (Đồng bộ captain_id thành BIGINT để khớp với users.id)
CREATE TABLE IF NOT EXISTS `teams` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL UNIQUE,
    `captain_id` BIGINT NOT NULL,
    `description` TEXT,
    `reputation_score` INT DEFAULT 100,
    `status` VARCHAR(50) NOT NULL,
    `banned_until` DATETIME DEFAULT NULL,
    `created_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_teams_captain_id`
        FOREIGN KEY (`captain_id`) REFERENCES `users` (`id`)
);

-- 3. Tạo bảng leagues (Sửa manager_id thành BIGINT)
CREATE TABLE IF NOT EXISTS `leagues` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `format` VARCHAR(50) NOT NULL,
    `number_of_teams` INT NOT NULL,
    `prize` TEXT,
    `status` VARCHAR(50) NOT NULL,
    `manager_id` BIGINT NOT NULL,
    `created_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_leagues_manager_id`
        FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`)
);

-- 4. Tạo bảng các thông báo giải đấu
CREATE TABLE IF NOT EXISTS `league_announcements` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `league_id` BIGINT NOT NULL,
    `title` VARCHAR(255) NOT NULL,
    `content` TEXT NOT NULL,
    `created_at` DATETIME NOT NULL,
    `updated_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_league_announcements_league_id`
        FOREIGN KEY (`league_id`) REFERENCES `leagues` (`id`) ON DELETE CASCADE
);

-- 5. Tạo bảng bình luận thông báo giải đấu
CREATE TABLE IF NOT EXISTS `league_announcement_comments` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `announcement_id` BIGINT NOT NULL,
    `user_id` BIGINT NOT NULL,
    `content` TEXT NOT NULL,
    `created_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_lac_announcement_id`
        FOREIGN KEY (`announcement_id`) REFERENCES `league_announcements` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_lac_user_id`
        FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
);

-- 6. Tạo bảng sân (venues) - Đổi manager_id thành BIGINT
CREATE TABLE IF NOT EXISTS `venues` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255) NOT NULL,
    `address` TEXT,
    `description` TEXT,
    `image_url` VARCHAR(255),
    `manager_id` BIGINT NOT NULL,
    `open_time` TIME NOT NULL,
    `close_time` TIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_venues_manager_id`
        FOREIGN KEY (`manager_id`) REFERENCES `users` (`id`)
);

-- 7. Tạo bảng các sân nhỏ (pitches)
CREATE TABLE IF NOT EXISTS `pitches` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(255),
    `pitch_type` VARCHAR(255),
    `is_active` BIT(1) NOT NULL,
    `base_price` DECIMAL(38,2),
    `venue_id` BIGINT NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_pitches_venue_id`
        FOREIGN KEY (`venue_id`) REFERENCES `venues` (`id`)
);

-- 8. Tạo bảng khung giờ master (time_slots)
CREATE TABLE IF NOT EXISTS `time_slots` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `slot_number` INT NOT NULL,
    `start_time` TIME NOT NULL,
    `end_time` TIME NOT NULL,
    `is_active` BIT(1) NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`),
    CONSTRAINT `uk_time_slots_slot_number`
        UNIQUE (`slot_number`)
);

-- 9. Tạo bảng luật giá (price_rules)
CREATE TABLE IF NOT EXISTS `price_rules` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `pitch_id` BIGINT,
    `slot_number` INT NOT NULL,
    `is_weekend` BIT(1) NOT NULL,
    `coefficient` DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_price_rules_pitch_id`
        FOREIGN KEY (`pitch_id`) REFERENCES `pitches` (`id`),
    CONSTRAINT `uk_price_rules_pitch_slot_weekend`
        UNIQUE (`pitch_id`, `slot_number`, `is_weekend`)
);

-- 10. Tạo bảng dịch vụ đi kèm (services)
CREATE TABLE IF NOT EXISTS `services` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `venue_id` BIGINT,
    `pitch_id` BIGINT,
    `name` VARCHAR(255),
    `description` TEXT,
    `price` DECIMAL(38,2),
    `unit` VARCHAR(255),
    `status` VARCHAR(50) DEFAULT 'ACTIVE',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_services_venue_id`
        FOREIGN KEY (`venue_id`) REFERENCES `venues` (`id`),
    CONSTRAINT `fk_services_pitch_id`
        FOREIGN KEY (`pitch_id`) REFERENCES `pitches` (`id`)
);

-- 11. Tạo bảng đơn đặt sân (bookings) - Đổi player_id thành BIGINT
CREATE TABLE IF NOT EXISTS `bookings` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `player_id` BIGINT,
    `pitch_id` BIGINT,
    `booking_date` DATE,
    `start_time` TIME,
    `end_time` TIME,
    `status` VARCHAR(255),
    `booking_type` VARCHAR(255),
    `total_price` DECIMAL(38,2),
    `pricing_mode` VARCHAR(50) DEFAULT 'AUTO',
    `created_at` DATETIME,
    `time_slot_id` BIGINT NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_bookings_player_id`
        FOREIGN KEY (`player_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_bookings_pitch_id`
        FOREIGN KEY (`pitch_id`) REFERENCES `pitches` (`id`),
    CONSTRAINT `fk_bookings_time_slot_id`
        FOREIGN KEY (`time_slot_id`) REFERENCES `time_slots` (`id`),
    CONSTRAINT `uk_bookings_date_pitch_slot`
        UNIQUE (`booking_date`, `pitch_id`, `time_slot_id`)
);

-- 12. Tạo bảng đánh giá sân bóng
CREATE TABLE IF NOT EXISTS `pitch_reviews` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `pitch_id` BIGINT NOT NULL,
    `player_id` BIGINT NOT NULL,
    `booking_id` BIGINT NOT NULL,
    `rating` INT NOT NULL,
    `content` TEXT NOT NULL,
    `created_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_pitch_reviews_pitch_id`
        FOREIGN KEY (`pitch_id`) REFERENCES `pitches` (`id`),
    CONSTRAINT `fk_pitch_reviews_player_id`
        FOREIGN KEY (`player_id`) REFERENCES `users` (`id`),
    CONSTRAINT `fk_pitch_reviews_booking_id`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `uk_pitch_reviews_booking_id`
        UNIQUE (`booking_id`)
);

-- 13. Chi tiết dịch vụ đã đặt
CREATE TABLE IF NOT EXISTS `booking_services` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `booking_id` BIGINT NOT NULL,
    `service_id` BIGINT NOT NULL,
    `quantity` INT NOT NULL,
    `price_at_booking` DECIMAL(38,2) NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_booking_services_booking_id`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_booking_services_service_id`
        FOREIGN KEY (`service_id`) REFERENCES `services` (`id`)
);

-- 14. Quản lý thanh toán đặt sân
CREATE TABLE IF NOT EXISTS `booking_payments` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `booking_id` BIGINT NOT NULL,
    `payer_id` BIGINT NOT NULL,
    `paid_amount` DECIMAL(38,2) NOT NULL,
    `payment_method` VARCHAR(50) NOT NULL,
    `payment_status` VARCHAR(50) NOT NULL,
    `paid_at` DATETIME,
    `created_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_booking_payments_booking_id`
        FOREIGN KEY (`booking_id`) REFERENCES `bookings` (`id`),
    CONSTRAINT `fk_booking_payments_payer_id`
        FOREIGN KEY (`payer_id`) REFERENCES `users` (`id`)
);

-- 15. Đăng ký tham gia giải đấu (Sửa captain_id sang BIGINT)
CREATE TABLE IF NOT EXISTS `league_registrations` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `league_id` BIGINT NOT NULL,
    `team_id` BIGINT NOT NULL,
    `captain_id` BIGINT NOT NULL,
    `status` VARCHAR(50) NOT NULL,
    `created_at` DATETIME NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_league_registrations_league_id`
        FOREIGN KEY (`league_id`) REFERENCES `leagues` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_league_registrations_team_id`
        FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_league_registrations_captain_id`
        FOREIGN KEY (`captain_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `uk_league_registrations_league_team`
        UNIQUE (`league_id`, `team_id`)
);

-- 16. Thành viên đội bóng
CREATE TABLE IF NOT EXISTS `team_members` (
    `team_id` BIGINT NOT NULL,
    `user_email` VARCHAR(255) NOT NULL,
    `status` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`team_id`, `user_email`),
    CONSTRAINT `fk_team_members_team_id`
        FOREIGN KEY (`team_id`) REFERENCES `teams` (`id`) ON DELETE CASCADE
);

-- 17. Lịch thi đấu trận đấu (matches)
CREATE TABLE IF NOT EXISTS `matches` (
    `id` BIGINT NOT NULL AUTO_INCREMENT,
    `venue_id` BIGINT NOT NULL,
    `host_team_id` BIGINT,
    `guest_team_id` BIGINT,
    `skill_level` VARCHAR(50) NOT NULL,
    `match_time` DATETIME NOT NULL,
    `status` VARCHAR(50) NOT NULL,
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_matches_venue_id`
        FOREIGN KEY (`venue_id`) REFERENCES `venues` (`id`),
    CONSTRAINT `fk_matches_host_team_id`
        FOREIGN KEY (`host_team_id`) REFERENCES `teams` (`id`),
    CONSTRAINT `fk_matches_guest_team_id`
        FOREIGN KEY (`guest_team_id`) REFERENCES `teams` (`id`)
);
