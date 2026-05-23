# 02_DB_DESIGN.md

MySQL 기준. 상세 정책은 `01_BUSINESS_RULES.md`.

## Tables
- users: id, email UNIQUE, password, name, nickname, role, created_at, updated_at
- point_wallets: id, user_id FK UNIQUE, balance, version, created_at, updated_at
- point_ledgers: id, user_id FK, room_id FK NULL, amount, balance_after, type, description, created_at
- rooms: id, owner_id FK, title, description, invite_code UNIQUE, status,
  duration_days, deadline_time, target_rate, stake_point, max_members,
  pot_point, proof_frequency_type, required_proof_count,
  mission_start_date, mission_end_date, created_at, updated_at
  - stake_point 범위: 1,000 이상 50,000 이하 (애플리케이션 레벨 검증)
  - duration_days 최소 28 (애플리케이션 레벨 검증)
  - WEEKLY: duration_days % 7 == 0 (애플리케이션 레벨 검증)
- room_members: id, room_id FK, user_id FK, role, status, staked_point, joined_at, staked_at, created_at, updated_at
- proofs: id, room_id FK, user_id FK, proof_date, content, file_url, file_original_name, file_stored_name, file_size, file_content_type, status, confirmed_at, created_at, updated_at
  - status: SUBMITTED, CONFIRMED만 허용 (REJECTED/EXPIRED/FAILED 금지)
- proof_confirmations: id, proof_id FK, room_id FK, confirmer_id FK, created_at
- settlements: id, room_id FK UNIQUE, total_pot_point, total_members, success_count, failed_count,
  total_required_proof_count, required_success_count,
  system_fee_point, system_bonus_point,
  settled_at, created_at, updated_at
  - system_fee_point: 전원 실패 시 30% 패널티 (기록용, 지갑 이동 없음)
  - system_bonus_point: 전원 성공 시 보너스 총합 (기록용)
- settlement_members: id, settlement_id FK, room_id FK, user_id FK,
  result_status, submitted_count, confirmed_count,
  required_success_count, reward_point, proof_rate,
  created_at, updated_at
  - result_status: SUCCESS / FAILED (SettlementMemberResult enum)

## Second Phase Tables
- room_activities: id, room_id FK, actor_id FK NULL, type, message, created_at
  - type: MEMBER_JOINED, MEMBER_STAKED, ROOM_READY, ROOM_STARTED, PROOF_SUBMITTED, PROOF_CONFIRMED, ROOM_SETTLED
- notifications: id, receiver_id FK, room_id FK NULL, type, title, message, read_at NULL, created_at
  - type: PROOF_SUBMITTED, PROOF_CONFIRMED, ROOM_STARTED, ROOM_SETTLED, MEMBER_JOINED, MEMBER_STAKED
- device_tokens: id, user_id FK, token UNIQUE, platform, active, created_at, updated_at
  - platform: ANDROID, IOS, WEB
- room_messages: id, room_id FK, sender_id FK, content, created_at

## Unique
- point_wallets.user_id
- rooms.invite_code
- room_members(room_id, user_id)
- proof_confirmations(proof_id, confirmer_id)
- settlements.room_id
- settlement_members(settlement_id, user_id)
- device_tokens.token

## Index (조회용)
- proofs(room_id, user_id, proof_date) — DAILY 일별/WEEKLY 주차별 제출 수 집계용
- room_activities(room_id, created_at)
- notifications(receiver_id, read_at, created_at)
- room_messages(room_id, created_at)

## 금지
- 예약어 테이블명 금지.
- rooms에 proof_type/is_public 금지.
- proofs.status에 FAILED/REJECTED/EXPIRED 추가 금지.
- 채팅 메시지 삭제/수정 테이블은 2차 초기 범위에서 제외.
- FCM topic 구독 방식은 2차 초기 범위에서 제외.
