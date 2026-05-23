# 16_room_activity_plan.md

## 1. 구현 목표

- 방 안에서 발생한 주요 이벤트를 RoomActivity로 기록한다.
- 방 멤버가 GET /api/rooms/{roomId}/activities 로 최근 활동 50개를 조회한다.
- 이후 Notification/FCM의 기반 이벤트로 활용할 수 있게 한다.

## 2. 생성할 패키지 구조

```
src/main/java/com/example/checkmate/domain/activity/
├── entity/ActivityType.java
├── entity/RoomActivity.java
├── repository/RoomActivityRepository.java
├── dto/RoomActivityResponse.java
├── service/RoomActivityService.java
└── controller/RoomActivityController.java
```

## 3. Entity 설계

ActivityType:
- MEMBER_JOINED, MEMBER_STAKED, ROOM_READY, ROOM_STARTED,
  PROOF_SUBMITTED, PROOF_CONFIRMED, ROOM_SETTLED

RoomActivity:
- id
- room (ManyToOne LAZY, NOT NULL)
- actor (ManyToOne LAZY, NULL 허용)
- type (ActivityType enum)
- message (NOT NULL)
- BaseTime 상속 (createdAt, updatedAt)

actor null 정책:
- ROOM_READY, ROOM_SETTLED → actor null
- 나머지 5종 → 행위자 UserEntity 저장

## 4. Repository 설계

RoomActivityRepository extends JpaRepository<RoomActivity, Long>:
- List<RoomActivity> findTop50ByRoomOrderByCreatedAtDesc(Room room)

## 5. Service 설계

RoomActivityService:

record(Room room, UserEntity actor, ActivityType type)
- type별 message 문자열 생성
- RoomActivity 저장 (기존 트랜잭션 내 REQUIRED)

getActivities(String email, Long roomId)
- roomId → Room 조회, 없으면 404
- email → UserEntity 조회
- roomMemberRepository.findByRoomAndUser → 없으면 403
- findTop50ByRoomOrderByCreatedAtDesc → DTO 변환 후 반환

## 6. Controller 설계

RoomActivityController @RequestMapping("/api/rooms"):

GET /{roomId}/activities
- Authentication에서 email 추출
- roomActivityService.getActivities(email, roomId) 호출
- 200 OK

## 7. 기존 서비스 연결 지점

RoomService 주입 추가: RoomActivityService

joinRoom()
- roomMemberRepository.save(member) 직후
- record(room, user, MEMBER_JOINED)

stakeRoom()
- member.stake() 직후
- record(room, user, MEMBER_STAKED)
- room.markReady() 직후
- record(room, null, ROOM_READY)

startRoom()
- room.start() 직후
- record(room, user, ROOM_STARTED)

ProofService 주입 추가: RoomActivityService

submitProof()
- proofRepository.save(proof) 직후
- record(room, user, PROOF_SUBMITTED)

confirmProof()
- proofConfirmationRepository.save() 직후
- record(proof.getRoom(), user, PROOF_CONFIRMED)

SettlementService 주입 추가: RoomActivityService

settle()
- room.settle() 직후
- record(room, null, ROOM_SETTLED)

주의:
- 기존 검증 로직 순서 변경 금지
- 기존 응답 DTO 구조 변경 금지
- 원본 기능 실패 시 Activity도 롤백 (같은 트랜잭션)

## 8. 응답 DTO

RoomActivityResponse (class + Lombok):
- Long id
- Long roomId
- Long actorId (nullable)
- String actorNickname (nullable)
- String type
- String message
- LocalDateTime createdAt

## 9. 메시지 문구

- MEMBER_JOINED: "{nickname}님이 방에 참여했어요."
- MEMBER_STAKED: "{nickname}님이 예치금을 납부했어요."
- ROOM_READY: "모든 멤버가 예치금을 납부했어요. 방장이 미션을 시작할 수 있어요."
- ROOM_STARTED: "{nickname}님이 미션을 시작했어요. 미션은 내일부터 진행돼요."
- PROOF_SUBMITTED: "{nickname}님이 인증을 제출했어요."
- PROOF_CONFIRMED: "{nickname}님이 인증을 확인했어요."
- ROOM_SETTLED: "미션이 정산 완료됐어요."

## 10. 구현 순서

1. ActivityType enum 생성
2. RoomActivity entity 생성
3. RoomActivityRepository 생성
4. RoomActivityResponse DTO 생성
5. RoomActivityService 생성
6. RoomActivityController 생성
7. RoomService에 record 연결 (joinRoom / stakeRoom / startRoom)
8. ProofService에 record 연결 (submitProof / confirmProof)
9. SettlementService에 record 연결 (settle)
10. ./gradlew.bat clean build
11. Swagger 테스트
12. CURRENT_STATE.md 갱신

## 11. 테스트 방법

1. 방 생성 (A)
2. B 방 참여 → GET activities → MEMBER_JOINED 확인
3. A 예치 → GET activities → MEMBER_STAKED 확인
4. B 예치 → GET activities → MEMBER_STAKED + ROOM_READY 확인
5. 방 시작 → GET activities → ROOM_STARTED 확인
6. 인증 제출 → GET activities → PROOF_SUBMITTED 확인
7. 인증 확인 → GET activities → PROOF_CONFIRMED 확인
8. 정산 → GET activities → ROOM_SETTLED 확인
9. 비멤버 GET activities → 403 확인
10. 없는 방 GET activities → 404 확인

빌드: ./gradlew.bat clean build

## 12. 주의사항

- 기존 MVP 기능 재구현 금지
- 기존 Room/Proof/Settlement 응답 구조 변경 금지
- Activity 저장 때문에 기존 기능 흐름이 바뀌면 안 됨
- FCM/Notification은 이번 단계에서 구현하지 않음
- WebSocket도 이번 단계에서 구현하지 않음
