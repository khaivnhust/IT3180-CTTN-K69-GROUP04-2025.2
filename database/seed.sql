SET NAMES 'utf8mb4';
SET FOREIGN_KEY_CHECKS = 0;

-- ============================================================
-- 1. XÓA SẠCH DỮ LIỆU CŨ THEO THỨ TỰ AN TOÀN
-- ============================================================
TRUNCATE TABLE `booking_services`;
TRUNCATE TABLE `booking_payments`;
TRUNCATE TABLE `pitch_reviews`;
TRUNCATE TABLE `league_announcement_comments`;
TRUNCATE TABLE `league_announcements`;
TRUNCATE TABLE `matches`;
TRUNCATE TABLE `league_registrations`;
TRUNCATE TABLE `leagues`;
TRUNCATE TABLE `bookings`;
TRUNCATE TABLE `price_rules`;
TRUNCATE TABLE `services`;
TRUNCATE TABLE `pitches`;
TRUNCATE TABLE `venues`;
TRUNCATE TABLE `team_members`;
TRUNCATE TABLE `teams`;
TRUNCATE TABLE `users`;
TRUNCATE TABLE `time_slots`;

-- Reset các bộ đếm ID tự động tăng
ALTER TABLE `users` AUTO_INCREMENT = 1;
ALTER TABLE `teams` AUTO_INCREMENT = 1;
ALTER TABLE `venues` AUTO_INCREMENT = 1;
ALTER TABLE `pitches` AUTO_INCREMENT = 1;
ALTER TABLE `price_rules` AUTO_INCREMENT = 1;
ALTER TABLE `services` AUTO_INCREMENT = 1;
ALTER TABLE `time_slots` AUTO_INCREMENT = 1;
ALTER TABLE `bookings` AUTO_INCREMENT = 1;
ALTER TABLE `pitch_reviews` AUTO_INCREMENT = 1;
ALTER TABLE `booking_payments` AUTO_INCREMENT = 1;
ALTER TABLE `matches` AUTO_INCREMENT = 1;
ALTER TABLE `leagues` AUTO_INCREMENT = 1;
ALTER TABLE `league_registrations` AUTO_INCREMENT = 1;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 2. CHÈN DỮ LIỆU MẪU (BẮT BUỘC THEO ĐÚNG THỨ TỰ KHÓA NGOẠI)
-- ============================================================

-- [Mục 1] Ghi nhận Users trước (Mật khẩu: 123456)
INSERT INTO `users` (`id`, `username`, `email`, `password`, `role`, `created_at`, `phone_number`, `avatar_url`, `membership_points`) VALUES
(1, 'owner_hoang', 'hoang.owner@football.vn', '$2a$10$gI6fyFeS.5m5GStiXfpl9OLT1UUZ7r6A7gt466M7H/boSx1ppfUzq', 'ADMIN', NOW(), '0909123456', NULL, 0),
(2, 'player_minh', 'minh.player@football.vn', '$2a$10$gI6fyFeS.5m5GStiXfpl9OLT1UUZ7r6A7gt466M7H/boSx1ppfUzq', 'PLAYER', NOW(), '0912345678', NULL, 0),
(3, 'player_tuan', 'tuan.player@football.vn', '$2a$10$gI6fyFeS.5m5GStiXfpl9OLT1UUZ7r6A7gt466M7H/boSx1ppfUzq', 'PLAYER', NOW(), '0987654321', NULL, 0);

-- [Mục 2] Ghi nhận Teams (Đội bóng)
INSERT INTO `teams` (`id`, `name`, `captain_id`, `description`, `reputation_score`, `status`, `created_at`) VALUES
(1, 'FC Mixi', 2, 'Doi bong phong trao khu vuc Cau Giay', 100, 'APPROVED', NOW()),
(2, 'FC Refund', 3, 'Giao luu vui ve, khong quau', 95, 'PENDING', NOW());

-- Cập nhật ngược lại team_id cho Users để khớp logic vòng của bạn
UPDATE `users` SET `team_id` = 1 WHERE `id` = 2;
UPDATE `users` SET `team_id` = 2 WHERE `id` = 3;

-- [Mục 3] Thành viên của các đội bóng
INSERT INTO `team_members` (`team_id`, `user_email`, `status`) VALUES
(1, 'minh.player@football.vn', 'ACTIVE'),
(1, 'member1@football.vn', 'ACTIVE'),
(1, 'member2@football.vn', 'INVITED'),
(2, 'tuan.player@football.vn', 'ACTIVE'),
(2, 'member3@football.vn', 'ACTIVE');

-- [Mục 4] Ghi nhận Cụm sân (Venues) liên kết tới Chủ sân (id = 1)
INSERT INTO `venues` (`id`, `name`, `address`, `description`, `image_url`, `manager_id`, `open_time`, `close_time`) VALUES
(1, 'Cum san Bong Da Yen Hoa', '123 Nguyen Chi Thanh, Cau Giay, Ha Noi', 'Cum san phuc vu cho phong trao va giai dau ban chuyen', 'https://images.unsplash.com/photo-1574629810360-7efbbe195018', 1, '06:30:00', '23:00:00');

-- [Mục 5] Danh sách các sân nhỏ thuộc Cụm sân 1
INSERT INTO `pitches` (`id`, `name`, `pitch_type`, `is_active`, `base_price`, `venue_id`) VALUES
(1, 'San 1 - 5 Nguoi', 'SAN_5', b'1', 150000.00, 1),
(2, 'San 2 - 5 Nguoi', 'SAN_5', b'1', 150000.00, 1),
(3, 'San 3 - 7 Nguoi', 'SAN_7', b'1', 250000.00, 1),
(4, 'San 4 - 7 Nguoi', 'SAN_7', b'1', 250000.00, 1),
(5, 'San 5 - 11 Nguoi', 'SAN_11', b'1', 500000.00, 1);

-- [Mục 6] Khung giờ hệ thống cố định (Time slots)
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

-- [Mục 7] Thiết lập hệ số nhân giá (Price Rules) theo Schema mới
INSERT INTO `price_rules` (`pitch_id`, `slot_number`, `is_weekend`, `coefficient`) VALUES
(1, 1, b'0', 1.00),
(1, 1, b'1', 1.20),
(1, 2, b'0', 1.00),
(1, 2, b'1', 1.20),
(2, 3, b'0', 1.00),
(2, 3, b'1', 1.20),
(3, 5, b'0', 1.00),
(3, 5, b'1', 1.20),
(4, 7, b'0', 1.00),
(4, 7, b'1', 1.20),
(5, 9, b'0', 1.00),
(5, 9, b'1', 1.20);

-- [Mục 8] Dịch vụ đi kèm tại cụm sân
INSERT INTO `services` (`venue_id`, `pitch_id`, `name`, `price`, `unit`, `status`) VALUES
(1, NULL, 'Nước khoáng', 10000.00, 'chai', 'ACTIVE'),
(1, NULL, 'Thuê áo bib', 25000.00, 'bộ', 'ACTIVE'),
(1, NULL, 'Bóng thi đấu', 150000.00, 'quả', 'ACTIVE');

-- [Mục 9] Dữ liệu lịch sử đặt sân (Bookings) phục vụ hiển thị Dashboard
INSERT INTO `bookings` (`id`, `player_id`, `pitch_id`, `booking_date`, `start_time`, `end_time`, `status`, `booking_type`, `total_price`, `created_at`, `time_slot_id`) VALUES
(1, 2, 1, DATE_SUB(CURDATE(), INTERVAL 7 DAY), '06:30:00', '08:00:00', 'PLAYING',   'MATCH',    350000.00, DATE_SUB(NOW(), INTERVAL 7 DAY), 1),
(2, 2, 2, DATE_SUB(CURDATE(), INTERVAL 6 DAY), '08:00:00', '09:30:00', 'PLAYING',   'TRAINING', 500000.00, DATE_SUB(NOW(), INTERVAL 6 DAY), 2),
(3, 2, 3, DATE_SUB(CURDATE(), INTERVAL 5 DAY), '09:30:00', '11:00:00', 'CANCELLED', 'MATCH',    900000.00, DATE_SUB(NOW(), INTERVAL 5 DAY), 3),
(4, 2, 1, DATE_SUB(CURDATE(), INTERVAL 4 DAY), '11:00:00', '12:30:00', 'PLAYING',   'FRIENDLY', 350000.00, DATE_SUB(NOW(), INTERVAL 4 DAY), 4),
(5, 2, 2, DATE_SUB(CURDATE(), INTERVAL 3 DAY), '12:30:00', '14:00:00', 'CANCELLED', 'MATCH',    500000.00, DATE_SUB(NOW(), INTERVAL 3 DAY), 5),
(6, 2, 3, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '14:00:00', '15:30:00', 'PLAYING',   'TOUR',     900000.00, DATE_SUB(NOW(), INTERVAL 2 DAY), 6),
(7, 2, 1, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '15:30:00', '17:00:00', 'PLAYING',   'MATCH',    350000.00, DATE_SUB(NOW(), INTERVAL 1 DAY), 7),
(8, 2, 1, '2026-06-06', '17:00:00', '18:30:00', 'CONFIRMED', 'SINGLE', 150000.00, NOW(), 8),
(9, 3, 2, '2026-06-06', '18:30:00', '20:00:00', 'CONFIRMED', 'SINGLE', 180000.00, NOW(), 9),
(10, 1, 3, '2026-06-06', '08:00:00', '09:30:00', 'MAINTENANCE', 'MAINTENANCE', 0.00, NOW(), 2);

-- [Mục 10] Đánh giá chất lượng từ khách hàng (Reviews)
INSERT INTO `pitch_reviews` (`pitch_id`, `player_id`, `booking_id`, `rating`, `content`, `created_at`) VALUES
(1, 2, 1, 5, 'Sân đẹp, chất lượng cỏ nhân tạo rất tốt', NOW()),
(2, 2, 2, 4, 'Giá cả hợp lý, hệ thống chiếu sáng ổn định', NOW());

-- [Mục 11] Kèo đấu giao lưu công khai (Matches)
INSERT INTO `matches` (`id`, `venue_id`, `host_team_id`, `guest_team_id`, `skill_level`, `match_time`, `status`) VALUES
(1, 1, 1, NULL, 'AVERAGE', DATE_ADD(NOW(), INTERVAL 2 DAY), 'OPEN'),
(2, 1, 1, 2, 'AVERAGE', DATE_ADD(NOW(), INTERVAL 3 DAY), 'MATCHED');

-- [Mục 12] Hệ thống giải đấu (Leagues) liên kết tới người quản lý (id = 1)
INSERT INTO `leagues` (`id`, `name`, `format`, `number_of_teams`, `prize`, `status`, `manager_id`, `created_at`) VALUES
(1, 'Giải Ngoại Hạng Yên Hòa 2026', 'ROUND_ROBIN', 4, 'Cúp vô địch + 10,000,000 VND', 'OPENING', 1, NOW()),
(2, 'Champions League Yên Hòa 2026', 'KNOCKOUT', 8, 'Cúp vô địch + 20,000,000 VND', 'OPENING', 1, NOW());
