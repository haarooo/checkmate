# 04_room_stake_research.md

## 핵심 파일 현황

| 파일 | 현재 상태 | 필요한 변경 |
|------|-----------|-------------|
| `PointWallet` | `addBalance()`만 존재 | `subtractBalance()` 추가 필요 |
| `PointLedger` | `create()`에 roomId 없음 (항상 null) | roomId 포함 factory 메서드 추가 필요 |
| `PointService` | 충전/조회만 존재 | stake용 차감 메서드 추가 필요 |
| `RoomMember` | `createOwner/createMember`만 존재 | `stake()` 메서드 추가 필요 |
| `Room` | potPoint 필드는 있으나 변경 메서드 없음 | `addPotPoint()`, `markReady()` 추가 필요 |
| `RoomMemberRepository` | 기본 쿼리만 존재 | `countByRoomAndStatus()` 추가 필요 |
| `RoomService` | stake 없음 | `stakeRoom()` 추가 필요 |
| `RoomController` | stake 없음 | `POST /api/rooms/{roomId}/stake` 추가 필요 |

## 흐름 정리

1. room 조회 → 404
2. roomMember 조회 → 403
3. room.status != RECRUITING → 409
4. member.status != JOINED → 409
5. wallet.balance < room.stakePoint → 400
6. wallet.subtractBalance(stakePoint)
7. PointLedger 생성 (amount 음수, roomId 포함, ROOM_STAKE)
8. member.stake(stakePoint) → status=STAKED, stakedPoint, stakedAt 설정
9. room.addPotPoint(stakePoint)
10. READY 조건 충족 시 room.markReady()

## READY 전환 조건
- `countByRoom(room) == room.getMaxMembers()` (인원 가득)
- `countByRoomAndStatus(room, STAKED) == room.getMaxMembers()` (전원 STAKED)
- 둘 다 만족 시 `room.markReady()` → status=READY

## 트랜잭션 / 의존성
- 전체 stakeRoom()을 단일 `@Transactional`로 처리
- RoomService → PointService 의존 추가 (UserService → PointService 패턴과 동일)
- PointWallet은 `@Version` 낙관적 락 이미 적용됨

## 제외 범위
- start, Proof, Settlement, ShareCard 구현 금지
- SecurityConfig, User, JWT, build.gradle 수정 금지
