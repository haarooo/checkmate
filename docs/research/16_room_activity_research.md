# 16_room_activity_research.md

## 1. 기능 목표

RoomActivity는 방 안에서 발생하는 주요 이벤트를 자동으로 기록하고,
방 멤버가 시간순 활동 피드로 확인할 수 있게 하는 기능이다.

목표:
- 방 참여, 예치, 시작, 인증 제출, 인증 확인, 정산 완료 이벤트 기록
- 방 상세 화면에서 "이 방에서 무슨 일이 있었는지" 보여주기
- 이후 Notification / FCM / 실시간 반영의 기반 이벤트로 활용

## 2. 왜 필요한가

문제:
- 현재는 방에 들어가도 어떤 일이 있었는지 흐름을 알기 어렵다.
- 누가 참여했는지, 누가 예치했는지, 누가 인증했는지 이벤트가 화면에 누적되지 않는다.
- 알림/FCM을 붙이려면 어떤 이벤트가 발생했는지 일관된 기록 지점이 필요하다.

해결:
- RoomActivity 테이블에 주요 이벤트를 기록한다.
- 조회 API로 방 멤버에게 활동 피드를 제공한다.
- 이후 NotificationService가 같은 이벤트를 기반으로 알림을 만들 수 있게 한다.

## 3. 기록할 이벤트

ActivityType:
- MEMBER_JOINED: 멤버가 방에 참여
- MEMBER_STAKED: 멤버가 예치금 납부
- ROOM_READY: 모든 멤버가 예치 완료되어 시작 가능 상태
- ROOM_STARTED: 방장이 미션 시작
- PROOF_SUBMITTED: 멤버가 인증 제출
- PROOF_CONFIRMED: 다른 멤버가 인증 확인
- ROOM_SETTLED: 방 정산 완료

## 4. 기록 위치 분석

기존 서비스 메서드 기준 record 호출 위치:

| 서비스 메서드 | ActivityType | 기록 시점 |
|---|---|---|
| RoomService.joinRoom() | MEMBER_JOINED | roomMemberRepository.save(member) 직후 |
| RoomService.stakeRoom() | MEMBER_STAKED | member.stake() 직후 |
| RoomService.stakeRoom() | ROOM_READY | room.markReady() 직후 (stakedCount == maxMembers 분기) |
| RoomService.startRoom() | ROOM_STARTED | room.start() 직후 |
| ProofService.submitProof() | PROOF_SUBMITTED | proofRepository.save(proof) 직후 |
| ProofService.confirmProof() | PROOF_CONFIRMED | proofConfirmationRepository.save() 직후 |
| SettlementService.settle() | ROOM_SETTLED | room.settle() 직후 |

중복 위험 분석:
- ROOM_READY: stakeRoom()이 findByIdForUpdate 비관적 락 사용 + totalCount/stakedCount 이중 조건으로 한 번만 진입. 중복 없음.
- PROOF_CONFIRMED: confirmProof()가 existsByProofAndConfirmer 체크 후 409 처리. 같은 confirmer 중복 없음. 이미 CONFIRMED 상태에 새 confirmer 확인 시 ProofConfirmation 저장 → PROOF_CONFIRMED 기록 1회. 정상.
- ROOM_SETTLED: settlementRepository UNIQUE + 409로 중복 정산 차단. ROOM_SETTLED 중복 없음.

## 5. Entity 설계 초안

RoomActivity 필드:
- id: Long (PK, AUTO_INCREMENT)
- room: Room (ManyToOne LAZY, FK room_id NOT NULL)
- actor: UserEntity (ManyToOne LAZY, FK actor_id NULL — 시스템 이벤트는 null)
- type: ActivityType (Enum, NOT NULL)
- message: String (화면 표시용 문구, NOT NULL)
- createdAt, updatedAt: BaseTime 상속

actor null 정책:
- MEMBER_JOINED, MEMBER_STAKED, ROOM_STARTED, PROOF_SUBMITTED, PROOF_CONFIRMED: 행위자 UserEntity 저장
- ROOM_READY: 시스템 이벤트. actor = null, 메시지로 표현
- ROOM_SETTLED: 정산 트리거 user를 actor로 저장 가능. 단, 방 멤버 누구나 실행 가능하므로 의미 있는 actor가 아님. null 권장.

BaseTime 상속 여부:
- Room, RoomMember, UserEntity 모두 BaseTime(createdAt + updatedAt) 상속 중.
- RoomActivity는 immutable이라 updatedAt이 항상 createdAt과 동일하지만 BaseTime 상속으로 일관성 유지.

## 6. DB 설계 확정

테이블명: room_activities

컬럼:
- id BIGINT AUTO_INCREMENT PK
- room_id BIGINT NOT NULL FK(rooms.id)
- actor_id BIGINT NULL FK(users.id)
- type VARCHAR NOT NULL
- message VARCHAR NOT NULL
- created_at DATETIME NOT NULL
- updated_at DATETIME NOT NULL (BaseTime, 실질적으로 created_at과 동일)

Index:
- room_activities(room_id, created_at) — 방별 시간순 조회용

정렬 정책:
- createdAt DESC (최신순) 권장.
- 이유: 기존 proof feed도 createdAt DESC 사용. 사용자가 가장 최근 이벤트를 먼저 보는 게 자연스럽다.
- 채팅(ASC, 오래된 메시지부터)과는 성격이 다름. 활동 피드는 "가장 최근에 무슨 일이?" 확인이 목적.

## 7. API 설계

GET /api/rooms/{roomId}/activities

권한:
- 방 멤버만 조회 가능
- 비멤버 → 403
- 없는 방 → 404

응답 DTO (RoomActivityResponse):
- id: Long
- roomId: Long
- actorId: Long (null 가능)
- actorNickname: String (null 가능)
- type: String (ActivityType enum name)
- message: String
- createdAt: LocalDateTime

페이징:
- 초기에는 최근 50건 고정 조회. Pageable 없이 단순하게 시작.
- 이유: 방 멤버 수는 maxMembers 이내, durationDays 최대 수개월. 이벤트 수는 수백 건 이하로 수렴.
- 향후 방 수가 많아지면 Pageable 추가. 현재는 오버엔지니어링.
- Repository: findTop50ByRoomOrderByCreatedAtDesc(room) 사용.

## 8. 패키지 구조

추천: domain/activity/ (독립 최상위 도메인)

```
src/main/java/com/example/checkmate/domain/activity/
├── controller/RoomActivityController.java
├── dto/RoomActivityResponse.java
├── entity/RoomActivity.java
├── entity/ActivityType.java
├── repository/RoomActivityRepository.java
└── service/RoomActivityService.java
```

비교:
- domain/room/activity/: room 하위에 두면 ProofService, SettlementService에서도 참조해야 하므로 room 도메인 의존성이 과도해짐.
- domain/activity/: RoomActivity가 room + proof + settlement 이벤트를 모두 포괄하는 독립 도메인. 기존 패턴(domain/proof/, domain/settlement/ 분리)과 일관성 있음.

결론: domain/activity/ 선택.

## 9. 트랜잭션 설계

기본 전파: REQUIRED (Spring 기본값).
- RoomService.joinRoom()은 @Transactional → RoomActivityService.record()가 같은 트랜잭션에 참여.
- 원본 트랜잭션 롤백 시 Activity 저장도 롤백. 정합성 보장.
- Activity 저장 실패(예: DB 오류)는 원본 이벤트도 롤백 → 개발 오류로 간주하고 롤백 허용.

별도 REQUIRES_NEW 사용 안 함:
- REQUIRES_NEW는 FCM/외부 API처럼 원본 실패와 독립이어야 할 때 사용.
- Activity 저장 실패가 원본 이벤트 실패로 이어지는 것은 MVP에서 수용 가능.
- 17~18단계 FCM에서는 트랜잭션 완료 후 @Async 처리로 분리 예정.

## 10. 메시지 문구 설계

서버에서 message 문자열을 생성하여 DB에 저장하는 방식 선택.

이유:
- 프론트(Flutter)가 type별 분기 없이 message를 바로 표시 가능 → 클라이언트 로직 단순.
- 다국어 지원이 현재 없으므로 단점 없음.
- 문구 변경 시 기존 데이터는 변경 안 되지만, 피드는 과거 이력이 그대로 보이는 게 자연스러움.

각 ActivityType별 메시지 템플릿:
- MEMBER_JOINED: "{nickname}님이 방에 참여했어요."
- MEMBER_STAKED: "{nickname}님이 예치금을 납부했어요."
- ROOM_READY: "모든 멤버가 예치금을 납부했어요. 방장이 미션을 시작할 수 있어요."
- ROOM_STARTED: "{nickname}님이 미션을 시작했어요. 미션은 내일부터 진행돼요."
- PROOF_SUBMITTED: "{nickname}님이 인증을 제출했어요."
- PROOF_CONFIRMED: "{nickname}님이 인증을 확인했어요."
- ROOM_SETTLED: "미션이 정산 완료됐어요."

메시지 생성 위치: RoomActivityService.record() 내부에서 ActivityType별 분기로 생성.

## 11. 기존 기능 영향 분석

joinRoom:
- 기존 로직 완료 후 record() 추가 호출만. 기존 검증/저장 순서 변경 없음.

stakeRoom:
- member.stake() → record(MEMBER_STAKED). room.markReady() → record(ROOM_READY). 기존 분기 내 추가.

startRoom:
- room.start() → record(ROOM_STARTED). 기존 로직 그대로.

submitProof:
- proofRepository.save(proof) → record(PROOF_SUBMITTED). 기존 검증/저장 순서 변경 없음.

confirmProof:
- proofConfirmationRepository.save() → record(PROOF_CONFIRMED). idempotent 처리 후 저장과 함께 기록.
- 주의: 이미 CONFIRMED proof에 새 confirmer 확인 시 Activity가 기록됨. 이는 의도된 동작 ("X님이 인증을 확인했어요.").

settle:
- 마지막 room.settle() 직후 record(ROOM_SETTLED). 기존 정산 순서 변경 없음.

기존 DB 영향:
- room_activities 신규 테이블. 기존 테이블 스키마 변경 없음.
- Hibernate DDL-auto 설정 확인 필요. update 모드라면 자동 생성, none/validate라면 수동 migration 필요.

## 12. 구현 위험과 대응

| 위험 | 상황 | 대응 |
|---|---|---|
| ROOM_READY 중복 | stakeRoom 동시 호출 | findByIdForUpdate 비관적 락으로 방어. 실제로는 한 명만 READY 전환. |
| PROOF_CONFIRMED 중복 | 같은 confirmer 재확인 | existsByProofAndConfirmer 체크 + 409. record() 도달 전 차단. |
| ROOM_SETTLED 중복 | settle() 동시 호출 | settlementRepository UNIQUE + findByIdForUpdate + 409. |
| LazyLoading | record() 내부에서 추가 조회 | record()는 이미 로드된 room, actor 참조만 사용. 추가 조회 없음. |
| 멤버 권한 누락 | GET activities 비멤버 접근 | getActivities()에서 roomMemberRepository.findByRoomAndUser 체크. |
| 순환 의존 | RoomService ↔ RoomActivityService | RoomActivityService는 RoomActivityRepository만 의존. 단방향 주입. 순환 없음. |

## 13. 테스트 전략

Swagger 순서:
1. 방 생성 (A)
2. B 방 참여 → GET activities → MEMBER_JOINED 확인
3. A 예치 → GET activities → MEMBER_STAKED 확인
4. B 예치 → GET activities → MEMBER_STAKED + ROOM_READY 확인
5. A 방 시작 → GET activities → ROOM_STARTED 확인
6. 인증 제출 → GET activities → PROOF_SUBMITTED 확인
7. 인증 확인 → GET activities → PROOF_CONFIRMED 확인
8. 정산 → GET activities → ROOM_SETTLED 확인
9. 비멤버 GET activities → 403 확인
10. 없는 방 GET activities → 404 확인

빌드:
- Windows: ./gradlew.bat clean build

## 14. 추천 결론

| 항목 | 결정 |
|---|---|
| 패키지 위치 | domain/activity/ |
| Entity 필드 | id, room, actor(nullable), type, message, BaseTime(createdAt/updatedAt) |
| ActivityType 7종 | MEMBER_JOINED, MEMBER_STAKED, ROOM_READY, ROOM_STARTED, PROOF_SUBMITTED, PROOF_CONFIRMED, ROOM_SETTLED |
| API 경로 | GET /api/rooms/{roomId}/activities |
| 정렬 방식 | createdAt DESC |
| 페이징 | 없음. findTop50ByRoomOrderByCreatedAtDesc 고정 조회 |
| record 호출 위치 | 각 서비스 원본 로직 성공 직후, 같은 트랜잭션 내 |
| 트랜잭션 전파 | REQUIRED (기본값). Activity 저장 실패 시 원본 롤백 허용 |
| message 방식 | 서버에서 문자열 생성 후 DB 저장 |

plan에서 확정할 사항:
- RoomActivity.create() 정적 팩토리 메서드 시그니처
- RoomActivityService.record() 메서드 구조 (오버로딩 vs 단일 메서드)
- Hibernate DDL-auto 설정 확인 후 migration 스크립트 필요 여부
- GET activities 응답 DTO 필드 최종 확정
