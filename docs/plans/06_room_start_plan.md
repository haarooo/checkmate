# 06_room_start_plan.md

## 목표
POST /api/rooms/{roomId}/start — OWNER 전용, READY → IN_PROGRESS 전환

## 수정 파일

### 1. Room.java
- `start(LocalDate missionStartDate, LocalDate missionEndDate)` 메서드 추가
- `this.status = IN_PROGRESS`, 두 날짜 필드 세팅

### 2. RoomService.java
- `startRoom(String email, Long roomId)` 추가, `@Transactional`
- 검증 순서:
  1. 404 (방 없음)
  2. 403 (비멤버)
  3. 403 (비OWNER)
  4. 409 (status != READY)
  5. 409 (currentCount != maxMembers)
  6. 409 (stakedCount != maxMembers)
- 성공: `missionStartDate = LocalDate.now().plusDays(1)`
         `missionEndDate = missionStartDate.plusDays(durationDays - 1)`
- 반환: `toDetailResponse(room, currentCount, myRole)`

### 3. RoomController.java
- `@PostMapping("/{roomId}/start")` 추가
- `Authentication` → `roomService.startRoom(email, roomId)`
- `ResponseEntity.ok(...)` 반환

## 불변 제약
- 신규 DTO 없음, 신규 Repository 메서드 없음
- join/stake는 RECRUITING 상태만 허용 (기존 코드 이미 보장)

## 검증
- `./gradlew.bat clean build` 성공
- Swagger: 정상 start 200, 비멤버 403, 비OWNER 403, READY아님/인원미달/미예치 409
