# 02_DB_DESIGN.md

MySQL 기준. 상세 정책은 `01_BUSINESS_RULES.md`.

## Tables
- users: id, email UNIQUE, password, name, nickname, role, created_at, updated_at
- point_wallets: id, user_id FK UNIQUE, balance, version, created_at, updated_at
- point_ledgers: id, user_id FK, room_id FK NULL, amount, balance_after, type, description, created_at
- rooms: id, owner_id FK, title, description, invite_code UNIQUE, status, duration_days, deadline_time, target_rate, stake_point, max_members, pot_point, mission_start_date, mission_end_date, created_at, updated_at
- room_members: id, room_id FK, user_id FK, role, status, staked_point, joined_at, staked_at, created_at, updated_at
- proofs: id, room_id FK, user_id FK, proof_date, content, file_url, file_original_name, file_stored_name, file_size, file_content_type, status, confirmed_at, created_at, updated_at
- proof_confirmations: id, proof_id FK, room_id FK, confirmer_id FK, created_at
- settlements: id, room_id FK UNIQUE, total_pot_point, success_count, reward_per_member, remainder_point, status, settled_at, created_at
- settlement_members: id, settlement_id FK, room_id FK, user_id FK, result, confirmed_count, proof_rate, reward_point, created_at

## Unique
point_wallets.user_id, rooms.invite_code, room_members(room_id,user_id), proof_confirmations(proof_id,confirmer_id), settlements.room_id, settlement_members(settlement_id,user_id) 권장.

## Index (조회용)
proofs(room_id,user_id,proof_date) — DAILY 일별/WEEKLY 주차별 제출 수 집계용

## 금지
예약어 테이블명 금지. rooms에 proof_type/is_public 금지.
