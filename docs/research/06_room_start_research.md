# 06_room_start_research.md

## 분석 대상
POST /api/rooms/{roomId}/start — OWNER가 READY 방을 IN_PROGRESS로 전환

## 기존 코드 패턴
- 쓰기 작업 패턴: `findByIdForUpdate`(비관적 락) → `findUserByEmail` → `findByRoomAndUser` → 검증 → 액션
- `stakeRoom` 메서드가 동일 패턴 사용 — startRoom도 동일하게 따른다
- `toDetailResponse`는 이미 nullable `missionStartDate/missionEndDate` 처리 중 (추가 변경 불필요)
- `RoomStatus.IN_PROGRESS`는 이미 선언돼 있음

## 핵심 발견
- `Room.java`에 `start()` 메서드 없음 → 추가 필요
- READY 상태 체크 후에도 `countByRoom`, `countByRoomAndStatus`로 인원/STAKED 조건을 명시적으로 재검증
  → 두 Repository 메서드 모두 이미 존재, 신규 추가 불필요

## 검증 순서
1. roomId 존재 → 404
2. 로그인 사용자 조회
3. 해당 방 멤버 여부 → 403
4. role == OWNER 여부 → 403
5. status == READY 여부 → 409
6. currentCount == maxMembers 여부 → 409
7. stakedCount == maxMembers 여부 → 409
8. Room.start() 호출 후 toDetailResponse 반환

## 변경 범위
- Room.java: `start()` 메서드 추가
- RoomService.java: `startRoom()` 추가
- RoomController.java: POST `/{roomId}/start` 엔드포인트 추가
- 새 DTO 불필요, 새 Repository 메서드 불필요

## 제외
- Proof, Settlement, ShareCard, FileUpload 미구현
- User/Point/Security/JWT/build.gradle/application.properties 수정 없음
