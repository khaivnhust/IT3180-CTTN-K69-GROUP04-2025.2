SET NAMES 'utf8mb4';
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. XÓA SẠCH DỮ LIỆU CŨ THEO THỨ TỰ AN TOÀN (BẰNG TRUNCATE)
-- ============================================================
TRUNCATE TABLE `player_match_statistics`;
TRUNCATE TABLE `league_standings`;
TRUNCATE TABLE `booking_services`;
TRUNCATE TABLE `booking_payments`;
TRUNCATE TABLE `pitch_reviews`;
TRUNCATE TABLE `notifications`;
TRUNCATE TABLE `league_announcement_comments`;
TRUNCATE TABLE `league_announcements`;
TRUNCATE TABLE `bookings`;
TRUNCATE TABLE `services`;
TRUNCATE TABLE `price_rules`;
TRUNCATE TABLE `pitches`;
TRUNCATE TABLE `match_requests`;
TRUNCATE TABLE `matches`;
TRUNCATE TABLE `league_registrations`;
TRUNCATE TABLE `leagues`;
TRUNCATE TABLE `venues`;
TRUNCATE TABLE `team_members`;
TRUNCATE TABLE `teams`;
TRUNCATE TABLE `password_reset_tokens`;
TRUNCATE TABLE `users`;
TRUNCATE TABLE `activity_logs`;
TRUNCATE TABLE `time_slots`;

-- Reset bộ đếm tự động tăng về 1 cho tất cả các bảng
ALTER TABLE `activity_logs` AUTO_INCREMENT = 1;
ALTER TABLE `users` AUTO_INCREMENT = 1;
ALTER TABLE `password_reset_tokens` AUTO_INCREMENT = 1;
ALTER TABLE `venues` AUTO_INCREMENT = 1;
ALTER TABLE `pitches` AUTO_INCREMENT = 1;
ALTER TABLE `price_rules` AUTO_INCREMENT = 1;
ALTER TABLE `services` AUTO_INCREMENT = 1;
ALTER TABLE `time_slots` AUTO_INCREMENT = 1;
ALTER TABLE `bookings` AUTO_INCREMENT = 1;
ALTER TABLE `pitch_reviews` AUTO_INCREMENT = 1;
ALTER TABLE `booking_payments` AUTO_INCREMENT = 1;
ALTER TABLE `teams` AUTO_INCREMENT = 1;
ALTER TABLE `matches` AUTO_INCREMENT = 1;
ALTER TABLE `leagues` AUTO_INCREMENT = 1;
ALTER TABLE `league_registrations` AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 2. CHÈN DỮ LIỆU MẪU ĐỒNG BỘ CẤU TRÚC HỆ THỐNG
-- ============================================================

-- [Mục 1] Khởi tạo danh sách Users (Password mã hóa BCrypt của "123456")
INSERT INTO `users` (`id`, `username`, `email`, `password`, `role`, `created_at`, `phone_number`, `avatar_url`, `membership_points`, `wallet_balance`) VALUES
(1, 'owner_hoang', 'hoang.owner@football.vn', '$2a$10$gI6fyFeS.5m5GStiXfpl9OLT1UUZ7r6A7gt466M7H/boSx1ppfUzq', 'ADMIN', NOW(), '0909123456', NULL, 0, 0.00),
(2, 'player_minh', 'minh.player@football.vn', '$2a$10$gI6fyFeS.5m5GStiXfpl9OLT1UUZ7r6A7gt466M7H/boSx1ppfUzq', 'PLAYER', NOW(), '0912345678', NULL, 0, 500000.00),
(3, 'player_tuan', 'tuan.player@football.vn', '$2a$10$gI6fyFeS.5m5GStiXfpl9OLT1UUZ7r6A7gt466M7H/boSx1ppfUzq', 'PLAYER', NOW(), '0987654321', NULL, 0, 200000.00)
ON DUPLICATE KEY UPDATE `password` = VALUES(`password`);

-- [Mục 2] Khởi tạo các Cụm sân (Venues)
INSERT INTO `venues` (`id`, `name`, `address`, `description`, `image_url`, `manager_id`, `open_time`, `close_time`, `latitude`, `longitude`) VALUES
(1, 'Cụm sân Bóng Đá Yên Hòa', '123 Nguyễn Chí Thanh, Cầu Giấy, Hà Nội', 'Cụm sân phục vụ cho phong trào và giải đấu bán chuyên', 'https://images.unsplash.com/photo-1574629810360-7efbbe195018', 1, '06:30:00', '23:00:00', 21.0278, 105.8053),
(2, 'Cụm sân Bóng Đá Dịch Vọng', '45 Trần Thái Tông, Cầu Giấy, Hà Nội', 'Sân cỏ nhân tạo chất lượng cao, có bãi đỗ xe rộng rãi', 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2', 1, '06:00:00', '22:00:00', 21.0315, 105.7924);

-- [Mục 3] Khởi tạo các Sân nhỏ (Pitches) thuộc các Cụm sân tương ứng
INSERT INTO `pitches` (`id`, `name`, `pitch_type`, `is_active`, `base_price`, `venue_id`) VALUES
(1, 'Sân 1 - Yên Hòa', 'SAN_5', b'1', 150000.00, 1),
(2, 'Sân 2 - Yên Hòa', 'SAN_5', b'1', 150000.00, 1),
(3, 'Sân 3 - Yên Hòa', 'SAN_7', b'1', 250000.00, 1),
(4, 'Sân 1 - Dịch Vọng', 'SAN_7', b'1', 260000.00, 2),
(5, 'Sân 2 - Dịch Vọng', 'SAN_11', b'1', 550000.00, 2);

-- [Mục 4] Khung giờ hệ thống cố định (Time Slots Master Data)
INSERT INTO `time_slots` (`id`, `slot_number`, `start_time`, `end_time`, `is_active`) VALUES
(1,  1,  '06:30:00', '08:00:00', b'1'),
(2,  2,  '08:00:00', '09:30:00', b'1'),
(3,  3,  '09:30:00', '11:00:00', b'1'),
(4,  4,  '11:00:00', '12:30:00', b'1'),
(5,  5,  '12:30:00', '14:00:00', b'1'),
(6,  6,  '14:00:00', '15:30:00', b'1'),
(7,  7,  '15:30:00', '17:00:00', b'1'),
(8,  8,  '17:00:00', '18:30:00', b'1'),
(9,  9,  '18:30:00', '20:00:00', b'1'),
(10, 10, '20:00:00', '21:30:00', b'1'),
(11, 11, '21:30:00', '23:00:00', b'1');

-- [Mục 5] Cấu hình hệ số nhân giá (Price Rules) chuẩn tỷ lệ coefficient
INSERT INTO `price_rules` (`pitch_id`, `slot_number`, `is_weekend`, `coefficient`) VALUES
(1, 1, b'0', 1.00), (1, 1, b'1', 1.20),
(1, 8, b'0', 1.00), (1, 8, b'1', 1.20),
(1, 9, b'0', 1.00), (1, 9, b'1', 1.20),
(1, 10, b'0', 1.00), (1, 10, b'1', 1.20),
(2, 3, b'0', 1.00), (2, 3, b'1', 1.20),
(2, 8, b'0', 1.00), (2, 8, b'1', 1.20),
(2, 9, b'0', 1.00), (2, 9, b'1', 1.20),
(3, 5, b'0', 1.00), (3, 5, b'1', 1.20),
(3, 8, b'0', 1.00), (3, 8, b'1', 1.20),
(3, 10, b'0', 1.00), (3, 10, b'1', 1.20),
(4, 7, b'0', 1.00), (4, 7, b'1', 1.20),
(4, 8, b'0', 1.00), (4, 8, b'1', 1.20),
(4, 9, b'0', 1.00), (4, 9, b'1', 1.20),
(4, 10, b'0', 1.00), (4, 10, b'1', 1.20),
(5, 8, b'0', 1.00), (5, 8, b'1', 1.20),
(5, 9, b'0', 1.00), (5, 9, b'1', 1.20);

-- [Mục 6] Danh mục dịch vụ đi kèm tại cụm sân
INSERT INTO `services` (`venue_id`, `pitch_id`, `name`, `description`, `price`, `unit`, `status`) VALUES
(1, NULL, 'Nước khoáng', 'Nước uống đóng chai', 10000.00, 'chai', 'ACTIVE'),
(1, NULL, 'Thuê áo bib', 'Áo bib phân đội', 25000.00, 'bộ', 'ACTIVE'),
(1, NULL, 'Bóng thi đấu', 'Bóng tiêu chuẩn sân 5/7/11', 150000.00, 'quả', 'ACTIVE');

-- [Mục 7] Đội bóng (Teams) và Thành viên Đội bóng
INSERT INTO `teams` (`id`, `name`, `captain_id`, `description`, `reputation_score`, `status`, `banned_until`, `created_at`, `skill_level`) VALUES
(1, 'FC Mixi', 2, 'Đội bóng phong trào khu vực Cầu Giấy', 100, 'APPROVED', NULL, NOW(), 'AVERAGE'),
(2, 'FC Refund', 3, 'Giao lưu vui vẻ, không quạu', 95, 'PENDING', NULL, NOW(), 'BELOW_AVERAGE'),
(3, 'FC Banned', 2, 'Đội bóng bị cấm thi đấu tạm thời', 80, 'BANNED', DATE_ADD(NOW(), INTERVAL 7 DAY), NOW(), 'WEAK');

INSERT INTO `team_members` (`team_id`, `user_email`, `status`) VALUES
(1, 'minh.player@football.vn', 'ACTIVE'),
(1, 'member1@football.vn', 'ACTIVE'),
(1, 'member2@football.vn', 'INVITED'),
(2, 'tuan.player@football.vn', 'ACTIVE'),
(2, 'member3@football.vn', 'ACTIVE'),
(3, 'minh.player@football.vn', 'ACTIVE'),
(3, 'banned_member@football.vn', 'ACTIVE');

-- Đồng bộ liên kết ngược team_id cho bảng users
UPDATE `users` SET `team_id` = 1 WHERE `id` = 2;
UPDATE `users` SET `team_id` = 2 WHERE `id` = 3;

-- [Mục 8] Tập lịch sử đơn đặt sân (Bookings) phục vụ kiểm thử biểu đồ
INSERT INTO `bookings` (`id`, `player_id`, `pitch_id`, `booking_date`, `start_time`, `end_time`, `status`, `booking_type`, `total_price`, `created_at`, `time_slot_id`) VALUES
(1, 2, 1, '2026-05-25', '17:00:00', '18:30:00', 'COMPLETED', 'SINGLE', 150000.00, '2026-05-24 10:00:00', 8),
(2, 3, 1, '2026-05-25', '18:30:00', '20:00:00', 'COMPLETED', 'SINGLE', 180000.00, '2026-05-24 11:00:00', 9),
(3, 2, 2, '2026-05-25', '17:00:00', '18:30:00', 'CANCELLED', 'SINGLE', 150000.00, '2026-05-24 12:00:00', 8),
(4, 2, 1, '2026-05-26', '20:00:00', '21:30:00', 'COMPLETED', 'SINGLE', 180000.00, '2026-05-25 09:00:00', 10),
(5, 3, 3, '2026-05-26', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 250000.00, '2026-05-25 14:00:00', 8),
(6, 2, 2, '2026-05-27', '18:30:00', '20:00:00', 'PLAYING', 'SINGLE', 150000.00, '2026-05-26 15:00:00', 9),
(7, 3, 4, '2026-05-27', '17:00:00', '18:30:00', 'CANCELLED', 'SINGLE', 260000.00, '2026-05-26 16:00:00', 8),
(8, 2, 1, '2026-05-28', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 150000.00, '2026-05-27 10:00:00', 8),
(9, 3, 5, '2026-05-28', '18:30:00', '20:00:00', 'CONFIRMED', 'SINGLE', 550000.00, '2026-05-27 11:00:00', 9),
(10, 2, 3, '2026-05-29', '20:00:00', '21:30:00', 'CONFIRMED', 'SINGLE', 300000.00, '2026-05-28 09:00:00', 10),
(11, 3, 4, '2026-05-29', '18:30:00', '20:00:00', 'CONFIRMED', 'SINGLE', 260000.00, '2026-05-28 14:00:00', 9),
(12, 2, 1, '2026-05-29', '18:30:00', '20:00:00', 'CANCELLED', 'SINGLE', 150000.00, '2026-05-28 15:00:00', 9),
(13, 3, 1, '2026-05-30', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 180000.00, '2026-05-29 10:00:00', 8),
(14, 2, 2, '2026-05-30', '18:30:00', '20:00:00', 'CONFIRMED', 'SINGLE', 180000.00, '2026-05-29 11:00:00', 9),
(15, 3, 3, '2026-05-30', '17:00:00', '18:30:00', 'CANCELLED', 'SINGLE', 300000.00, '2026-05-29 12:00:00', 8),
(16, 2, 1, '2026-05-31', '18:30:00', '20:00:00', 'CONFIRMED', 'SINGLE', 180000.00, '2026-05-30 09:00:00', 9),
(17, 3, 4, '2026-05-31', '20:00:00', '21:30:00', 'CONFIRMED', 'SINGLE', 312000.00, '2026-05-30 14:00:00', 10),
(18, 2, 1, '2026-06-01', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 150000.00, '2026-05-31 10:00:00', 8),
(19, 3, 2, '2026-06-01', '18:30:00', '20:00:00', 'CONFIRMED', 'SINGLE', 150000.00, '2026-05-31 11:00:00', 9),
(20, 2, 3, '2026-06-01', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 250000.00, '2026-05-31 12:00:00', 8),
(21, 3, 4, '2026-06-01', '17:00:00', '18:30:00', 'CANCELLED', 'SINGLE', 260000.00, '2026-05-31 13:00:00', 8),
(22, 2, 1, '2026-06-02', '17:00:00', '18:30:00', 'PLAYING', 'SINGLE', 150000.00, '2026-06-01 10:00:00', 8),
(23, 3, 2, '2026-06-02', '18:30:00', '20:00:00', 'PLAYING', 'SINGLE', 150000.00, '2026-06-01 11:00:00', 9),
(24, 2, 3, '2026-06-02', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 250000.00, '2026-06-01 12:00:00', 8),
(25, 3, 4, '2026-06-02', '18:30:00', '20:00:00', 'PENDING', 'SINGLE', 260000.00, '2026-06-01 13:00:00', 9),
(26, 2, 5, '2026-06-02', '17:00:00', '18:30:00', 'CANCELLED', 'SINGLE', 550000.00, '2026-06-01 14:00:00', 8);

-- [Mục 9] Đánh giá chất lượng (Reviews) từ người dùng công khai
INSERT INTO `pitch_reviews` (`id`, `pitch_id`, `player_id`, `booking_id`, `rating`, `content`, `created_at`) VALUES
(1, 1, 2, 1, 5, 'Sân đẹp, mặt cỏ tốt', '2026-05-25 21:00:00'),
(2, 1, 3, 2, 4, 'Ánh sáng ổn, đặt sân nhanh', '2026-05-25 22:00:00');

UPDATE `users` SET `membership_points` = 10 WHERE `id` IN (2, 3);

-- [Mục 10] Cáp kèo thi đấu giao hữu (Matches) công khai
INSERT INTO `matches` (`id`, `venue_id`, `host_team_id`, `guest_team_id`, `skill_level`, `match_time`, `status`, `pitch_type`, `time_slot_id`) VALUES
(1, 1, 1, NULL, 'AVERAGE', DATE_ADD(NOW(), INTERVAL 2 DAY), 'OPEN', 5, 8),
(2, 1, 1, 2, 'AVERAGE', DATE_ADD(NOW(), INTERVAL 3 DAY), 'MATCHED', 5, 9),
(3, 2, 2, NULL, 'WEAK', DATE_ADD(NOW(), INTERVAL 1 DAY), 'CANCELLED', 7, 8),
(4, 2, 1, NULL, 'GOOD', DATE_ADD(NOW(), INTERVAL 4 DAY), 'OPEN', 11, 10);

-- [Mục 11] Giải đấu thể thao quy mô (Leagues)
INSERT INTO `leagues` (`id`, `name`, `format`, `number_of_teams`, `prize`, `status`, `manager_id`, `created_at`) VALUES
(1, 'Giải Ngoại Hạng Yên Hòa 2026', 'ROUND_ROBIN', 4, 'Cúp vô địch + 10,000,000 VND', 'OPENING', 1, NOW()),
(2, 'Champions League Yên Hòa 2026', 'KNOCKOUT', 8, 'Cúp vô địch + 20,000,000 VND', 'OPENING', 1, NOW());
