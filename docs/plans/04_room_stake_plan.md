# 04_room_stake_plan.md

## 수정 파일 목록 (순서대로)

### 1. PointWallet.java
- `subtractBalance(long amount)` 추가 — balance -= amount

### 2. PointLedger.java
- `createWithRoom(user, roomId, amount, balanceAfter, type, description)` factory 추가
- 기존 `create()`는 유지

### 3. PointService.java
- `deductForRoomStake(UserEntity user, long stakePoint, Long roomId)` 추가
  - 잔액 부족 → 400
  - subtractBalance → createWithRoom(ROOM_STAKE, 음수 amount) → ledger save

### 4. RoomMember.java
- `stake(long stakedPoint)` 추가 — status=STAKED, stakedPoint 설정, stakedAt=now

### 5. Room.java
- `addPotPoint(long amount)` 추가 — potPoint += amount
- `markReady()` 추가 — status=READY

### 6. RoomMemberRepository.java
- `countByRoomAndStatus(Room room, RoomMemberStatus status)` 추가

### 7. RoomService.java
- `PointService` 의존성 추가
- `stakeRoom(String email, Long roomId)` 추가
  - room 404 / member 403 / room.status 409 / member.status 409 / 잔액 400
  - pointService.deductForRoomStake() 호출
  - member.stake() / room.addPotPoint()
  - READY 조건 충족 시 room.markReady()
  - return toDetailResponse()

### 8. RoomController.java
- `POST /api/rooms/{roomId}/stake` 추가
  - 응답: 200 + RoomDetailResponse

## 검증
- 잔액 부족 → 400 확인
- room status != RECRUITING → 409 확인
- member status != JOINED → 409 (중복 stake 방지)
- 정상 stake → PointLedger amount 음수, roomId 포함 확인
- 전원 stake 후 room.status == READY 확인
- 빌드: `./gradlew.bat clean build`

## 제외
- start / Proof / Settlement / ShareCard
- SecurityConfig, User, JWT, build.gradle
