# 03_API_SPEC.md

세부 정책은 `01_BUSINESS_RULES.md`. PATCH 대신 PUT.

## User
- POST `/api/users/signup`
- POST `/api/users/login`
- GET `/api/users/me`
- PUT `/api/users/me` 선택

## Point
- GET `/api/points/me`
- GET `/api/points/me/ledgers`
- POST `/api/points/test/charge`

## Room
- POST `/api/rooms`
  - DAILY: durationDays >= 28. WEEKLY: durationDays >= 28 AND durationDays % 7 == 0. 위반 시 400.
  - stakePoint 1,000 이상 50,000 이하. 위반 시 400.
- GET `/api/rooms`
- GET `/api/rooms/{roomId}`
  - 방 멤버만 조회 가능. 비멤버 → 403, 없는 방 → 404.
  - 응답에 ownerId, ownerNickname, myRole, myMemberStatus, createdAt, members 목록 포함.
  - inviteCode: 6자리 직접 입력 코드.
  - inviteLinkToken: URL 초대 링크 토큰.
  - members: userId, nickname, role, status, stakedPoint, stakedAt, joinedAt.
- GET `/api/rooms/invite/{inviteCode}`
- POST `/api/rooms/{roomId}/join`
- POST `/api/rooms/{roomId}/stake`
- POST `/api/rooms/{roomId}/start`
- GET `/api/rooms/{roomId}/members`
- GET `/api/rooms/{roomId}/today-status`
- GET `/api/rooms/{roomId}/members/stats`
- PUT `/api/rooms/{roomId}` 선택
- DELETE `/api/rooms/{roomId}/members/me` 선택

## Proof
- POST `/api/rooms/{roomId}/proofs` multipart/form-data
  - content/file 중 하나 필수
  - DAILY: 당일 제출 수 < requiredProofCount, WEEKLY: 주차 제출 수 < requiredProofCount, 초과 시 409
  - deadlineTime 이후 제출 → 409
- GET `/api/rooms/{roomId}/proofs`
- GET `/api/proofs/{proofId}`
- POST `/api/proofs/{proofId}/confirm`
  - 본인 확인 금지 → 403
  - 중복 ProofConfirmation (같은 confirmer) → 409
  - CONFIRMED 전환. 이미 CONFIRMED 상태 proof에 새 confirmer 확인 → 200 (idempotent, confirmedAt 유지)
- DELETE `/api/proofs/{proofId}` 선택

## Settlement
- POST `/api/rooms/{roomId}/settle`
  - 방 멤버 누구나 실행 가능 (OWNER 전용 아님). 비멤버 → 403.
  - room.status != IN_PROGRESS → 409
  - Asia/Seoul 기준 today <= missionEndDate → 409 (당일 정산 불가)
  - 이미 Settlement 존재 (settlements.room_id UNIQUE) → 409
  - 성공 시 200, room.status = SETTLED, RoomMember.status = SUCCESS/FAILED
- GET `/api/rooms/{roomId}/settlement`
  - 방 멤버만 조회 가능. 비멤버 → 403, 없는 방 → 404.
  - 정산 미완료 방 → 409.
  - 응답: settlementId, totalPotPoint, successCount, failedCount, systemFeePoint, systemBonusPoint, settledAt, members.

## Post-MVP 후보
- GET `/api/rooms/{roomId}/records`
- GET `/api/rooms/{roomId}/share-card/me`
- GET `/api/rooms/{roomId}/share-card/group`

## Status
400 요청 오류, 401 인증 실패, 403 권한 없음, 404 없음, 409 중복/상태 충돌.
