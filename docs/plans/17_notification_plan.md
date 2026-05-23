# 17_notification_plan.md

## 1. 구현 목표

- 사용자 개인 알림을 Notification DB에 저장한다.
- 로그인 사용자가 자신의 알림 목록을 조회한다.
- 미읽음 알림 개수를 조회한다.
- 단건 읽음 처리와 전체 읽음 처리를 제공한다.
- FCM 발송은 18단계에서 구현한다.

## 2. 17단계 구현 범위

이번 단계에서 구현할 NotificationType은 4종으로 제한한다.

- PROOF_SUBMITTED
- PROOF_CONFIRMED
- ROOM_STARTED
- ROOM_SETTLED

제외:
- MEMBER_JOINED
- MEMBER_STAKED
- ROOM_READY
- FCM
- DeviceToken
- WebSocket 실시간 알림

이유:
- 인증 제출/확인/시작/정산이 사용자에게 가장 중요한 알림이다.
- 참여/예치 알림까지 넣으면 초기 알림이 과도해질 수 있다.
- 참여/예치 이벤트는 RoomActivity에 이미 기록된다.

## 3. 생성할 패키지 구조

```
src/main/java/com/example/checkmate/domain/notification/
├── entity/NotificationType.java
├── entity/Notification.java
├── repository/NotificationRepository.java
├── dto/NotificationResponse.java
├── dto/UnreadCountResponse.java
├── service/NotificationService.java
└── controller/NotificationController.java
```

## 4. Entity 설계

NotificationType:
- PROOF_SUBMITTED
- PROOF_CONFIRMED
- ROOM_STARTED
- ROOM_SETTLED

Notification:
- id
- receiver (ManyToOne LAZY, NOT NULL)
- room (ManyToOne LAZY, NULL 허용)
- type (NotificationType, NOT NULL)
- title (NOT NULL, length=100)
- message (NOT NULL, length=255)
- readAt (LocalDateTime, NULL = 미읽음)
- BaseTime 상속

정책:
- readAt == null 이면 미읽음
- readAt != null 이면 읽음
- 17단계 4종은 모두 room 저장 가능

## 5. Repository 설계

NotificationRepository:

```java
List<Notification> findTop50ByReceiverOrderByCreatedAtDesc(UserEntity receiver);

long countByReceiverAndReadAtIsNull(UserEntity receiver);

@Modifying
@Query("update Notification n set n.readAt = :readAt
       where n.receiver = :receiver and n.readAt is null")
int markAllAsRead(@Param("receiver") UserEntity receiver,
                  @Param("readAt") LocalDateTime readAt);
```

## 6. DTO 설계

NotificationResponse:
- Long id
- Long roomId (nullable)
- String type
- String title
- String message
- boolean read
- LocalDateTime readAt (nullable)
- LocalDateTime createdAt

UnreadCountResponse:
- long unreadCount

## 7. Service 설계

NotificationService:

조회/처리 메서드:
- getMyNotifications(String email)
- getUnreadCount(String email)
- markAsRead(String email, Long notificationId)
- markAllAsRead(String email)

저장 메서드:
- notify(Room room, UserEntity receiver, NotificationType type, UserEntity actor)

notify 동작:
- type + actor + room 기반으로 title/message 생성
- Notification 저장 (호출부 트랜잭션 참여)

markAsRead 권한:
- 없는 notification → 404
- 타인 notification → 403
- 이미 읽은 notification → 200, readAt 유지 (idempotent)

## 8. Controller 설계

NotificationController @RequestMapping("/api/notifications"):

- GET / → getMyNotifications
- GET /unread-count → getUnreadCount
- PUT /{notificationId}/read → markAsRead
- PUT /read-all → markAllAsRead

Authentication.getName()으로 email 추출.

## 9. 알림 대상 규칙

| 서비스 메서드 | NotificationType | 수신 대상 |
|---|---|---|
| RoomService.startRoom() | ROOM_STARTED | 방 멤버 전체 (OWNER 포함) |
| ProofService.submitProof() | PROOF_SUBMITTED | 작성자 제외 방 멤버 전체 |
| ProofService.confirmProof() | PROOF_CONFIRMED | proof.getUser() 단건 |
| SettlementService.settle() | ROOM_SETTLED | 방 멤버 전체 |

## 10. 메시지 문구

ROOM_STARTED:
- title: "미션이 시작됐어요"
- message: "{roomTitle} 미션이 시작됐어요. 내일부터 인증을 진행해요."

PROOF_SUBMITTED:
- title: "새 인증이 올라왔어요"
- message: "{nickname}님이 인증을 제출했어요. 확인해 주세요."

PROOF_CONFIRMED:
- title: "내 인증이 확인됐어요"
- message: "{nickname}님이 내 인증을 확인했어요."

ROOM_SETTLED:
- title: "정산이 완료됐어요"
- message: "{roomTitle} 정산 결과를 확인해 주세요."

ROOM_STARTED / ROOM_SETTLED → actor null 허용, room.getTitle() 사용
PROOF_SUBMITTED / PROOF_CONFIRMED → actor 필수 (actorNickname 검증)

## 11. 기존 서비스 연결 지점

RoomService.startRoom()
- roomActivityService.record(...) 직후
- 방 멤버 전체 순회 → notificationService.notify(room, member.getUser(), ROOM_STARTED, null)

ProofService.submitProof()
- roomActivityService.record(...) 직후
- 방 멤버 전체 조회 후 작성자 제외 순회 → notify(room, receiver, PROOF_SUBMITTED, user)

ProofService.confirmProof()
- roomActivityService.record(...) 직후
- notificationService.notify(proof.getRoom(), proof.getUser(), PROOF_CONFIRMED, user)

SettlementService.settle()
- roomActivityService.record(...) 직후
- 방 멤버 전체 순회 → notify(room, member.getUser(), ROOM_SETTLED, null)

주의:
- 기존 응답 DTO 구조 변경 금지
- 기존 검증 로직 순서 변경 금지
- RoomActivity record → Notification notify 순서 유지

## 12. 트랜잭션

- notify()는 @Transactional 없이 호출부 트랜잭션에 참여
- Notification 저장 실패 시 원본 이벤트도 롤백
- 18단계 FCM은 @TransactionalEventListener(AFTER_COMMIT) 또는 @Async로 트랜잭션 밖 처리

## 13. 구현 순서

1. NotificationType enum 생성
2. Notification entity 생성
3. NotificationRepository 생성
4. NotificationResponse DTO 생성
5. UnreadCountResponse DTO 생성
6. NotificationService 생성
7. NotificationController 생성
8. RoomService.startRoom에 notify 연결
9. ProofService.submitProof에 notify 연결
10. ProofService.confirmProof에 notify 연결
11. SettlementService.settle에 notify 연결
12. ./gradlew.bat clean build
13. Swagger 테스트
14. CURRENT_STATE.md 갱신

## 14. 테스트 방법

1. 방 생성 (A)
2. B 방 참여 → A/B 예치
3. 방 시작 → A/B GET /api/notifications → ROOM_STARTED 확인
4. A 인증 제출 → B GET /api/notifications → PROOF_SUBMITTED 확인
5. B 인증 확인 → A GET /api/notifications → PROOF_CONFIRMED 확인
6. 정산 → A/B GET /api/notifications → ROOM_SETTLED 확인
7. GET /api/notifications/unread-count 미읽음 수 확인
8. PUT /api/notifications/{id}/read → 단건 읽음 → unread-count 감소 확인
9. PUT /api/notifications/read-all → unread-count = 0 확인
10. 타인 notification 읽음 → 403 확인
11. 없는 notification 읽음 → 404 확인

빌드: ./gradlew.bat clean build

## 15. 주의사항

- FCM / DeviceToken / WebSocket 구현 금지
- MEMBER_JOINED / MEMBER_STAKED 알림 이번 단계 제외
- 기존 RoomActivity 기능 훼손 금지
- 기존 MVP 응답 DTO 구조 변경 금지
