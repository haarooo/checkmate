-- =========================================================
-- Checkmate Demo Data
-- 모든 테스트 계정 비밀번호: 12345678
-- MySQL 기준
-- =========================================================

SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE proof_confirmations;
TRUNCATE TABLE proofs;
TRUNCATE TABLE settlement_members;
TRUNCATE TABLE settlements;
TRUNCATE TABLE room_messages;
TRUNCATE TABLE notifications;
TRUNCATE TABLE room_activities;
TRUNCATE TABLE device_tokens;
TRUNCATE TABLE room_members;
TRUNCATE TABLE point_ledgers;
TRUNCATE TABLE point_wallets;
TRUNCATE TABLE rooms;
TRUNCATE TABLE users;

SET FOREIGN_KEY_CHECKS = 1;

-- =========================================================
-- 1. Users
-- password = 12345678
-- =========================================================

INSERT INTO users (
    id, email, password, name, nickname, role, created_at, updated_at
) VALUES
      (1, 'hwanbin@test.com', '$2a$10$txzBpPslZiTyoGlBBjGKVevdr.RzFzSWa9IbXFvNQmW/OvfKaUDyW', '유환빈', '환빈', 'ROLE_USER', NOW(), NOW()),
      (2, 'minsu@test.com',   '$2a$10$txzBpPslZiTyoGlBBjGKVevdr.RzFzSWa9IbXFvNQmW/OvfKaUDyW', '김민수', '민수', 'ROLE_USER', NOW(), NOW()),
      (3, 'jiyoon@test.com',  '$2a$10$txzBpPslZiTyoGlBBjGKVevdr.RzFzSWa9IbXFvNQmW/OvfKaUDyW', '박지윤', '지윤', 'ROLE_USER', NOW(), NOW()),
      (4, 'seoyeon@test.com', '$2a$10$txzBpPslZiTyoGlBBjGKVevdr.RzFzSWa9IbXFvNQmW/OvfKaUDyW', '이서연', '서연', 'ROLE_USER', NOW(), NOW()),
      (5, 'doyun@test.com',   '$2a$10$txzBpPslZiTyoGlBBjGKVevdr.RzFzSWa9IbXFvNQmW/OvfKaUDyW', '최도윤', '도윤', 'ROLE_USER', NOW(), NOW()),
      (6, 'yuna@test.com',    '$2a$10$txzBpPslZiTyoGlBBjGKVevdr.RzFzSWa9IbXFvNQmW/OvfKaUDyW', '정유나', '유나', 'ROLE_USER', NOW(), NOW());

-- =========================================================
-- 2. Point Wallets
-- 시연 흐름에 맞춰 예치/정산 반영 후 잔액
-- =========================================================

INSERT INTO point_wallets (
    id, user_id, balance, version, created_at, updated_at
) VALUES
      (1, 1, 89667, 0, NOW(), NOW()),
      (2, 2, 96667, 0, NOW(), NOW()),
      (3, 3, 91666, 0, NOW(), NOW()),
      (4, 4, 70000, 0, NOW(), NOW()),
      (5, 5, 88000, 0, NOW(), NOW()),
      (6, 6, 88000, 0, NOW(), NOW());

-- =========================================================
-- 3. Rooms
-- 1: 진행중 DAILY
-- 2: 정산완료 WEEKLY
-- 3: READY
-- 4: 모집중
-- 5: 진행중 WEEKLY
-- =========================================================

INSERT INTO rooms (
    id, owner_id, title, description,
    invite_code, invite_link_token,
    status, duration_days, deadline_time, target_rate,
    stake_point, max_members, pot_point,
    mission_start_date, mission_end_date,
    proof_frequency_type, required_proof_count,
    created_at, updated_at
) VALUES
      (1, 1, '5월 헬스장 매일 인증방', '매일 운동 인증하고 서로 확인해주는 방입니다.',
       'A1B2C3', 'demo-invite-health-daily-00000001',
       'IN_PROGRESS', 30, '23:59:00', 80,
       10000, 4, 40000,
       DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 19 DAY),
       'DAILY', 1,
       DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),

      (2, 2, '4주 다이어트 정산 완료방', '정산 결과 화면 시연용 방입니다.',
       'D1E2F3', 'demo-invite-diet-settled-00000002',
       'SETTLED', 28, '22:00:00', 80,
       20000, 4, 80000,
       DATE_SUB(CURDATE(), INTERVAL 35 DAY), DATE_SUB(CURDATE(), INTERVAL 8 DAY),
       'WEEKLY', 3,
       DATE_SUB(NOW(), INTERVAL 40 DAY), NOW()),

      (3, 3, '아침 러닝 4주 방', '전원 예치 완료. 방장이 시작하면 다음 날부터 진행됩니다.',
       'R1U2N3', 'demo-invite-running-ready-00000003',
       'READY', 28, '09:00:00', 80,
       5000, 3, 15000,
       NULL, NULL,
       'WEEKLY', 4,
       DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),

      (4, 5, '퇴근 후 홈트 모집방', '초대 링크와 초대 코드로 참여하는 모집중 방입니다.',
       'H1O2M3', 'demo-invite-home-training-00000004',
       'RECRUITING', 30, '23:00:00', 80,
       3000, 5, 0,
       NULL, NULL,
       'DAILY', 1,
       DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

      (5, 1, '주 3회 필라테스 챌린지', 'WEEKLY 인증 방식 확인용 진행중 방입니다.',
       'P1I2L3', 'demo-invite-pilates-weekly-00000005',
       'IN_PROGRESS', 56, '21:00:00', 80,
       7000, 3, 21000,
       DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 41 DAY),
       'WEEKLY', 3,
       DATE_SUB(NOW(), INTERVAL 15 DAY), NOW());

-- =========================================================
-- 4. Room Members
-- =========================================================

INSERT INTO room_members (
    id, room_id, user_id, role, status,
    staked_point, joined_at, staked_at,
    created_at, updated_at
) VALUES
-- Room 1: IN_PROGRESS DAILY
(1, 1, 1, 'OWNER',  'STAKED', 10000, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(2, 1, 2, 'MEMBER', 'STAKED', 10000, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(3, 1, 3, 'MEMBER', 'STAKED', 10000, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),
(4, 1, 4, 'MEMBER', 'STAKED', 10000, DATE_SUB(NOW(), INTERVAL 12 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 12 DAY), NOW()),

-- Room 2: SETTLED
(5, 2, 2, 'OWNER',  'SUCCESS', 20000, DATE_SUB(NOW(), INTERVAL 40 DAY), DATE_SUB(NOW(), INTERVAL 39 DAY), DATE_SUB(NOW(), INTERVAL 40 DAY), NOW()),
(6, 2, 1, 'MEMBER', 'SUCCESS', 20000, DATE_SUB(NOW(), INTERVAL 40 DAY), DATE_SUB(NOW(), INTERVAL 39 DAY), DATE_SUB(NOW(), INTERVAL 40 DAY), NOW()),
(7, 2, 3, 'MEMBER', 'SUCCESS', 20000, DATE_SUB(NOW(), INTERVAL 40 DAY), DATE_SUB(NOW(), INTERVAL 39 DAY), DATE_SUB(NOW(), INTERVAL 40 DAY), NOW()),
(8, 2, 4, 'MEMBER', 'FAILED',  20000, DATE_SUB(NOW(), INTERVAL 40 DAY), DATE_SUB(NOW(), INTERVAL 39 DAY), DATE_SUB(NOW(), INTERVAL 40 DAY), NOW()),

-- Room 3: READY
(9,  3, 3, 'OWNER',  'STAKED', 5000, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(10, 3, 5, 'MEMBER', 'STAKED', 5000, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),
(11, 3, 6, 'MEMBER', 'STAKED', 5000, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), NOW()),

-- Room 4: RECRUITING
(12, 4, 5, 'OWNER', 'JOINED', 0, DATE_SUB(NOW(), INTERVAL 1 DAY), NULL, DATE_SUB(NOW(), INTERVAL 1 DAY), NOW()),

-- Room 5: IN_PROGRESS WEEKLY
(13, 5, 1, 'OWNER',  'STAKED', 7000, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
(14, 5, 5, 'MEMBER', 'STAKED', 7000, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW()),
(15, 5, 6, 'MEMBER', 'STAKED', 7000, DATE_SUB(NOW(), INTERVAL 15 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 15 DAY), NOW());

-- =========================================================
-- 5. Point Ledgers
-- =========================================================

INSERT INTO point_ledgers (
    id, user_id, room_id, amount, balance_after, type, description, created_at
) VALUES
-- signup bonus
(1, 1, NULL, 100000, 100000, 'SIGNUP_BONUS', '회원가입 보너스', DATE_SUB(NOW(), INTERVAL 50 DAY)),
(2, 2, NULL, 100000, 100000, 'SIGNUP_BONUS', '회원가입 보너스', DATE_SUB(NOW(), INTERVAL 50 DAY)),
(3, 3, NULL, 100000, 100000, 'SIGNUP_BONUS', '회원가입 보너스', DATE_SUB(NOW(), INTERVAL 50 DAY)),
(4, 4, NULL, 100000, 100000, 'SIGNUP_BONUS', '회원가입 보너스', DATE_SUB(NOW(), INTERVAL 50 DAY)),
(5, 5, NULL, 100000, 100000, 'SIGNUP_BONUS', '회원가입 보너스', DATE_SUB(NOW(), INTERVAL 50 DAY)),
(6, 6, NULL, 100000, 100000, 'SIGNUP_BONUS', '회원가입 보너스', DATE_SUB(NOW(), INTERVAL 50 DAY)),

-- room 1 stake
(10, 1, 1, -10000, 90000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 11 DAY)),
(11, 2, 1, -10000, 90000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 11 DAY)),
(12, 3, 1, -10000, 90000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 11 DAY)),
(13, 4, 1, -10000, 90000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 11 DAY)),

-- room 2 stake
(20, 1, 2, -20000, 70000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 39 DAY)),
(21, 2, 2, -20000, 70000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 39 DAY)),
(22, 3, 2, -20000, 70000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 39 DAY)),
(23, 4, 2, -20000, 70000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 39 DAY)),

-- room 2 settlement reward
(30, 2, 2, 20000, 90000, 'ROOM_SETTLEMENT_REFUND', '정산 예치금 반환', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(31, 2, 2, 6667, 96667, 'ROOM_SETTLEMENT_REWARD', '정산 보상', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(32, 1, 2, 20000, 90000, 'ROOM_SETTLEMENT_REFUND', '정산 예치금 반환', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(33, 1, 2, 6667, 96667, 'ROOM_SETTLEMENT_REWARD', '정산 보상', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(34, 3, 2, 20000, 90000, 'ROOM_SETTLEMENT_REFUND', '정산 예치금 반환', DATE_SUB(NOW(), INTERVAL 7 DAY)),
(35, 3, 2, 6666, 96666, 'ROOM_SETTLEMENT_REWARD', '정산 보상', DATE_SUB(NOW(), INTERVAL 7 DAY)),

-- room 3 stake
(40, 3, 3, -5000, 91666, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(41, 5, 3, -5000, 95000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(42, 6, 3, -5000, 95000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 1 DAY)),

-- room 5 stake
(50, 1, 5, -7000, 89667, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 14 DAY)),
(51, 5, 5, -7000, 88000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 14 DAY)),
(52, 6, 5, -7000, 88000, 'ROOM_STAKE', '방 예치금', DATE_SUB(NOW(), INTERVAL 14 DAY));

-- =========================================================
-- 6. Proofs: Room 1, Room 5
-- =========================================================

INSERT INTO proofs (
    id, room_id, user_id, proof_date, content,
    file_url, file_original_name, file_stored_name, file_size, file_content_type,
    status, confirmed_at, created_at, updated_at
) VALUES
-- Room 1: 오늘/최근 인증
(1, 1, 1, CURDATE(), '오늘 하체 운동 완료! 스쿼트 5세트 했습니다.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),

(2, 1, 2, CURDATE(), '출근 전 유산소 40분 완료했습니다.', NULL, NULL, NULL, NULL, NULL,
 'SUBMITTED', NULL, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR)),

(3, 1, 3, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '어제 등 운동 인증합니다.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 22 HOUR), DATE_SUB(NOW(), INTERVAL 24 HOUR), DATE_SUB(NOW(), INTERVAL 22 HOUR)),

(4, 1, 4, DATE_SUB(CURDATE(), INTERVAL 1 DAY), '야근 후 홈트 완료.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 21 HOUR), DATE_SUB(NOW(), INTERVAL 23 HOUR), DATE_SUB(NOW(), INTERVAL 21 HOUR)),

(5, 1, 1, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '가슴/삼두 운동 완료.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),

(6, 1, 2, DATE_SUB(CURDATE(), INTERVAL 2 DAY), '러닝머신 5km 완료.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),

-- Room 5: WEEKLY 인증
(201, 5, 1, CURDATE(), '이번 주 필라테스 1회차 완료.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR)),

(202, 5, 5, CURDATE(), '주간 인증 제출합니다. 오늘 코어 수업 완료.', NULL, NULL, NULL, NULL, NULL,
 'SUBMITTED', NULL, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),

(203, 5, 6, DATE_SUB(CURDATE(), INTERVAL 3 DAY), '필라테스 2회차 완료.', NULL, NULL, NULL, NULL, NULL,
 'CONFIRMED', DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY));

-- Proof confirmations for Room 1, Room 5

INSERT INTO proof_confirmations (
    proof_id, room_id, confirmer_id, created_at, updated_at
) VALUES
      (1, 1, 2, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),
      (3, 1, 1, DATE_SUB(NOW(), INTERVAL 22 HOUR), DATE_SUB(NOW(), INTERVAL 22 HOUR)),
      (4, 1, 2, DATE_SUB(NOW(), INTERVAL 21 HOUR), DATE_SUB(NOW(), INTERVAL 21 HOUR)),
      (5, 1, 3, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
      (6, 1, 1, DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
      (201, 5, 5, DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR)),
      (203, 5, 1, DATE_SUB(NOW(), INTERVAL 3 DAY), DATE_SUB(NOW(), INTERVAL 3 DAY));

-- =========================================================
-- 7. Proofs: Room 2 SETTLED 데이터 대량 생성
-- totalRequired = 12
-- requiredSuccess = 10
-- user1: 11 confirmed SUCCESS
-- user2: 12 confirmed SUCCESS
-- user3: 10 confirmed SUCCESS
-- user4: 7 confirmed FAILED
-- =========================================================

DROP TEMPORARY TABLE IF EXISTS demo_nums;
CREATE TEMPORARY TABLE demo_nums (n INT PRIMARY KEY);

INSERT INTO demo_nums (n) VALUES
                              (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12);

-- user1: 11 confirmed
INSERT INTO proofs (
    id, room_id, user_id, proof_date, content,
    file_url, file_original_name, file_stored_name, file_size, file_content_type,
    status, confirmed_at, created_at, updated_at
)
SELECT
    100 + n,
    2,
    1,
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 35 DAY), INTERVAL n DAY),
    CONCAT('정산 완료방 환빈 인증 ', n, '회차'),
    NULL, NULL, NULL, NULL, NULL,
    'CONFIRMED',
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY)
FROM demo_nums
WHERE n <= 11;

-- user2: 12 confirmed
INSERT INTO proofs (
    id, room_id, user_id, proof_date, content,
    file_url, file_original_name, file_stored_name, file_size, file_content_type,
    status, confirmed_at, created_at, updated_at
)
SELECT
    120 + n,
    2,
    2,
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 35 DAY), INTERVAL n DAY),
    CONCAT('정산 완료방 민수 인증 ', n, '회차'),
    NULL, NULL, NULL, NULL, NULL,
    'CONFIRMED',
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY)
FROM demo_nums
WHERE n <= 12;

-- user3: 10 confirmed
INSERT INTO proofs (
    id, room_id, user_id, proof_date, content,
    file_url, file_original_name, file_stored_name, file_size, file_content_type,
    status, confirmed_at, created_at, updated_at
)
SELECT
    140 + n,
    2,
    3,
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 35 DAY), INTERVAL n DAY),
    CONCAT('정산 완료방 지윤 인증 ', n, '회차'),
    NULL, NULL, NULL, NULL, NULL,
    'CONFIRMED',
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY)
FROM demo_nums
WHERE n <= 10;

-- user4: 7 confirmed
INSERT INTO proofs (
    id, room_id, user_id, proof_date, content,
    file_url, file_original_name, file_stored_name, file_size, file_content_type,
    status, confirmed_at, created_at, updated_at
)
SELECT
    160 + n,
    2,
    4,
    DATE_ADD(DATE_SUB(CURDATE(), INTERVAL 35 DAY), INTERVAL n DAY),
    CONCAT('정산 완료방 서연 인증 ', n, '회차'),
    NULL, NULL, NULL, NULL, NULL,
    'CONFIRMED',
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY),
    DATE_ADD(DATE_SUB(NOW(), INTERVAL 35 DAY), INTERVAL n DAY)
FROM demo_nums
WHERE n <= 7;

INSERT INTO proof_confirmations (
    proof_id, room_id, confirmer_id, created_at, updated_at
)
SELECT
    id,
    room_id,
    CASE
        WHEN user_id = 1 THEN 2
        WHEN user_id = 2 THEN 1
        WHEN user_id = 3 THEN 1
        WHEN user_id = 4 THEN 2
        END AS confirmer_id,
    confirmed_at,
    confirmed_at
FROM proofs
WHERE room_id = 2
  AND status = 'CONFIRMED';

DROP TEMPORARY TABLE IF EXISTS demo_nums;

-- =========================================================
-- 8. Settlement Result for Room 2
-- 일부 성공 케이스:
-- failedPot = 20,000
-- successCount = 3
-- reward: 26,667 / 26,667 / 26,666 / 0
-- =========================================================

INSERT INTO settlements (
    id, room_id,
    total_pot_point, total_members, success_count, failed_count,
    total_required_proof_count, required_success_count,
    system_fee_point, system_bonus_point,
    settled_at, created_at, updated_at
) VALUES
    (1, 2,
     80000, 4, 3, 1,
     12, 10,
     0, 0,
     DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY));

INSERT INTO settlement_members (
    id, settlement_id, room_id, user_id,
    result_status, submitted_count, confirmed_count,
    required_success_count, reward_point, proof_rate,
    created_at, updated_at
) VALUES
      (1, 1, 2, 2, 'SUCCESS', 12, 12, 10, 26667, 100.00, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY)),
      (2, 1, 2, 1, 'SUCCESS', 11, 11, 10, 26667, 91.67,  DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY)),
      (3, 1, 2, 3, 'SUCCESS', 10, 10, 10, 26666, 83.33,  DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY)),
      (4, 1, 2, 4, 'FAILED',  7,  7,  10, 0,     58.33,  DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY));

-- =========================================================
-- 9. Room Activities
-- =========================================================

INSERT INTO room_activities (
    id, room_id, actor_id, type, message, created_at, updated_at
) VALUES
      (1, 1, 1, 'MEMBER_STAKED', '환빈님이 예치금을 납부했어요.', DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY)),
      (2, 1, NULL, 'ROOM_READY', '모든 멤버가 예치금을 납부했어요. 방장이 미션을 시작할 수 있어요.', DATE_SUB(NOW(), INTERVAL 11 DAY), DATE_SUB(NOW(), INTERVAL 11 DAY)),
      (3, 1, 1, 'ROOM_STARTED', '환빈님이 미션을 시작했어요. 미션은 내일부터 진행돼요.', DATE_SUB(NOW(), INTERVAL 10 DAY), DATE_SUB(NOW(), INTERVAL 10 DAY)),
      (4, 1, 1, 'PROOF_SUBMITTED', '환빈님이 인증을 제출했어요.', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR)),
      (5, 1, 2, 'PROOF_CONFIRMED', '민수님이 인증을 확인했어요.', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),
      (6, 1, 2, 'PROOF_SUBMITTED', '민수님이 인증을 제출했어요.', DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR)),

      (10, 2, NULL, 'ROOM_SETTLED', '미션이 정산 완료됐어요.', DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY)),

      (20, 3, NULL, 'ROOM_READY', '모든 멤버가 예치금을 납부했어요. 방장이 미션을 시작할 수 있어요.', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),

      (30, 5, 1, 'ROOM_STARTED', '환빈님이 미션을 시작했어요. 미션은 내일부터 진행돼요.', DATE_SUB(NOW(), INTERVAL 14 DAY), DATE_SUB(NOW(), INTERVAL 14 DAY)),
      (31, 5, 1, 'PROOF_SUBMITTED', '환빈님이 인증을 제출했어요.', DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR)),
      (32, 5, 5, 'PROOF_CONFIRMED', '도윤님이 인증을 확인했어요.', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR));

-- =========================================================
-- 10. Notifications
-- user1 계정으로 로그인하면 알림함 시연 가능
-- =========================================================

INSERT INTO notifications (
    id, receiver_id, room_id, type, title, message, read_at, created_at, updated_at
) VALUES
      (1, 1, 1, 'PROOF_SUBMITTED', '새 인증이 올라왔어요', '민수님이 인증을 제출했어요. 확인해 주세요.', NULL, DATE_SUB(NOW(), INTERVAL 1 HOUR), DATE_SUB(NOW(), INTERVAL 1 HOUR)),
      (2, 1, 1, 'PROOF_CONFIRMED', '내 인증이 확인됐어요', '민수님이 내 인증을 확인했어요.', NULL, DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),
      (3, 1, 2, 'ROOM_SETTLED', '정산이 완료됐어요', '4주 다이어트 정산 완료방 정산 결과를 확인해 주세요.', NULL, DATE_SUB(NOW(), INTERVAL 7 DAY), DATE_SUB(NOW(), INTERVAL 7 DAY)),
      (4, 2, 1, 'PROOF_SUBMITTED', '새 인증이 올라왔어요', '환빈님이 인증을 제출했어요. 확인해 주세요.', NULL, DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR)),
      (5, 5, 5, 'PROOF_SUBMITTED', '새 인증이 올라왔어요', '환빈님이 인증을 제출했어요. 확인해 주세요.', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR));

-- =========================================================
-- 11. Room Messages
-- 채팅 화면 시연용
-- =========================================================

INSERT INTO room_messages (
    id, room_id, sender_id, content, created_at, updated_at
) VALUES
      (1, 1, 1, '오늘 인증 다들 마감 전에 올려주세요!', DATE_SUB(NOW(), INTERVAL 6 HOUR), DATE_SUB(NOW(), INTERVAL 6 HOUR)),
      (2, 1, 2, '저는 출근 전에 유산소 하고 올릴게요.', DATE_SUB(NOW(), INTERVAL 5 HOUR), DATE_SUB(NOW(), INTERVAL 5 HOUR)),
      (3, 1, 3, '좋아요. 확인도 서로 바로 해줍시다.', DATE_SUB(NOW(), INTERVAL 4 HOUR), DATE_SUB(NOW(), INTERVAL 4 HOUR)),
      (4, 1, 1, '하체 운동 완료했습니다!', DATE_SUB(NOW(), INTERVAL 3 HOUR), DATE_SUB(NOW(), INTERVAL 3 HOUR)),
      (5, 1, 2, '확인했어요. 오늘도 성공!', DATE_SUB(NOW(), INTERVAL 2 HOUR), DATE_SUB(NOW(), INTERVAL 2 HOUR)),

      (10, 5, 1, '이번 주 목표는 3회 인증입니다.', DATE_SUB(NOW(), INTERVAL 2 DAY), DATE_SUB(NOW(), INTERVAL 2 DAY)),
      (11, 5, 5, '오늘 코어 수업 듣고 인증 올릴게요.', DATE_SUB(NOW(), INTERVAL 1 DAY), DATE_SUB(NOW(), INTERVAL 1 DAY)),
      (12, 5, 6, '저는 수요일, 금요일, 일요일로 갈게요.', DATE_SUB(NOW(), INTERVAL 12 HOUR), DATE_SUB(NOW(), INTERVAL 12 HOUR));