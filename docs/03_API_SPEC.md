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
- GET `/api/rooms`
- GET `/api/rooms/{roomId}`
- GET `/api/rooms/invite/{inviteCode}`
- POST `/api/rooms/{roomId}/join`
- POST `/api/rooms/{roomId}/stake`
- POST `/api/rooms/{roomId}/start`
- GET `/api/rooms/{roomId}/members`
- GET `/api/rooms/{roomId}/today`
- GET `/api/rooms/{roomId}/records`
- GET `/api/rooms/{roomId}/members/stats`
- PUT `/api/rooms/{roomId}` 선택
- DELETE `/api/rooms/{roomId}/members/me` 선택

## Proof
- POST `/api/rooms/{roomId}/proofs` multipart/form-data
  - content/file 중 하나 필수
  - DAILY: 당일 제출 수 < requiredProofCount, WEEKLY: 주차 제출 수 < requiredProofCount, 초과 시 409
- GET `/api/rooms/{roomId}/proofs`
- GET `/api/proofs/{proofId}`
- POST `/api/proofs/{proofId}/confirm`
- DELETE `/api/proofs/{proofId}` 선택

## Settlement
- POST `/api/rooms/{roomId}/settle`
- GET `/api/rooms/{roomId}/settlement`

## ShareCard
- GET `/api/rooms/{roomId}/share-card/me`
- GET `/api/rooms/{roomId}/share-card/group`

## Status
400 요청 오류, 401 인증 실패, 403 권한 없음, 404 없음, 409 중복/상태 충돌.
