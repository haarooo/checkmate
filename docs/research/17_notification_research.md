# 17_notification_research.md

## 1. 기능 목표

앱 내부 알림함을 구축한다.
이벤트 발생 시 수신 대상 사용자별로 Notification을 DB에 저장하고,
사용자가 자신의 알림 목록 조회, 읽음 처리를 할 수 있게 한다.

FCM/DeviceToken은 이번 단계에서 구현하지 않는다.
18단계에서 FCM 발송을 붙일 때 트랜잭션 밖으로 분리할 수 있게 설계한다.

## 2. Notification과 RoomActivity의 차이

| 항목 | RoomActivity | Notification |
|---|---|---|
| 목적 | 방 전체 이벤트 타임라인 | 개인 수신 알림함 |
| 수신 주체 | 방 멤버 전체 공유 | receiver 개인 |
| 읽음 관리 | 없음 | readAt |
| 저장 건수 | 이벤트당 1건 | 수신자 수만큼 N건 |
| 삭제 | 없음 | 없음 (readAt으로만 관리) |

같은 이벤트가 RoomActivity와 Notification 양쪽에 기록될 수 있다.
예: PROOF_SUBMITTED → RoomActivity 1건 + 방 멤버(작성자 제외)별 Notification N건.

## 3. NotificationType 후보

DB 설계 기준 (02_DB_DESIGN.md):
- PROOF_SUBMITTED
- PROOF_CONFIRMED
- ROOM_STARTED
- ROOM_SETTLED
- MEMBER_JOINED
- MEMBER_STAKED

01_BUSINESS_RULES.md 알림 섹션에 명시된 타입: 4종
(PROOF_SUBMITTED, PROOF_CONFIRMED, ROOM_STARTED, ROOM_SETTLED)

MEMBER_JOINED / MEMBER_STAKED는 DB 설계에는 포함되어 있으나
비즈니스 규칙 알림 섹션에 대상이 명시되지 않았다.
→ plan에서 포함 여부와 대상 확정.

## 4. 이벤트별 알림 대상

| NotificationType | 수신 대상 | 근거 |
|---|---|---|
| PROOF_SUBMITTED | 작성자를 제외한 방 멤버 전체 | 01_BUSINESS_RULES.md 명시 |
| PROOF_CONFIRMED | 인증 작성자 (proof.getUser()) | 01_BUSINESS_RULES.md 명시 |
| ROOM_STARTED | 방 멤버 전체 (OWNER 포함) | 01_BUSINESS_RULES.md 명시 |
| ROOM_SETTLED | 방 멤버 전체 | 01_BUSINESS_RULES.md 명시 |
| MEMBER_JOINED | 미명시 → plan 확정 | 후보: 방장 단독 또는 기존 멤버 전체 |
| MEMBER_STAKED | 미명시 → plan 확정 | 후보: 방장 단독 |

17단계 구현 범위: 명시된 4종만 우선 구현.
MEMBER_JOINED / MEMBER_STAKED는 plan에서 포함 여부 확정 후 추가.

## 5. Entity 설계

Notification:
- id: Long (PK, AUTO_INCREMENT)
- receiver: UserEntity (ManyToOne LAZY, FK receiver_id NOT NULL)
- room: Room (ManyToOne LAZY, FK room_id NULL)
- type: NotificationType (Enum, NOT NULL)
- title: String (NOT NULL, length=100) — 짧은 제목 ("인증 확인 완료")
- message: String (NOT NULL, length=255) — 상세 문구 ("홍길동님이 인증을 확인했어요.")
- readAt: LocalDateTime (NULL = 미읽음)
- BaseTime 상속 (createdAt, updatedAt)

room nullable 이유:
- PROOF_CONFIRMED는 어느 방의 인증인지 room 정보가 있음 → room 저장
- 시스템 알림 확장 여부를 고려해 nullable 허용

title 분리 이유:
- FCM 알림은 title + body 구조가 표준
- 앱 알림함에서도 제목/내용 분리가 UI에 유리
- RoomActivity.message는 단일 문구, Notification은 title + message 이원화

## 6. API 설계

GET /api/notifications
- 본인 알림 목록 조회 (비로그인 401)
- createdAt DESC, 최근 50건
- 응답: id, type, title, message, roomId(nullable), readAt(nullable), createdAt

GET /api/notifications/unread-count
- 본인 미읽음 알림 개수 (readAt IS NULL)
- 응답: { count: Long }

PUT /api/notifications/{notificationId}/read
- 단건 읽음 처리 (readAt = now)
- 본인 알림만 가능. 타인 알림 → 403
- 없는 알림 → 404
- 이미 읽은 알림 → idempotent 200 반환 (readAt 유지)

PUT /api/notifications/read-all
- 본인 미읽음 알림 전체 readAt = now 일괄 처리
- 읽을 알림 없어도 200 반환

## 7. 패키지 구조

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

domain/activity/ 패턴과 동일한 독립 최상위 도메인으로 분리.

## 8. 기존 서비스 연결 후보

NotificationService.notify(Room room, UserEntity receiver, NotificationType type)
- 단건 저장. 복수 수신자는 호출부에서 루프.

연결 위치:

RoomService.startRoom()
- roomActivityService.record() 직후
- 방 멤버 전체에게 notify(ROOM_STARTED) 루프

ProofService.submitProof()
- roomActivityService.record() 직후
- 작성자 제외 방 멤버에게 notify(PROOF_SUBMITTED) 루프

ProofService.confirmProof()
- roomActivityService.record() 직후
- proof.getUser()에게 notify(PROOF_CONFIRMED) 단건

SettlementService.settle()
- roomActivityService.record() 직후
- 방 멤버 전체에게 notify(ROOM_SETTLED) 루프

주의:
- 기존 응답 DTO 구조 변경 금지
- RoomActivity.record() 호출 뒤에 notify() 호출 (Activity → Notification 순서)
- 방 멤버 목록은 각 서비스에 이미 로드된 members 리스트 재사용 가능

## 9. 트랜잭션 원칙

17단계:
- NotificationService.notify()는 @Transactional 없이 호출부 트랜잭션에 참여
- Notification 저장 실패 → 원본 이벤트도 롤백 (RoomActivity와 동일 정책)
- FCM 발송 없음

18단계 확장 방향:
- Spring ApplicationEventPublisher로 이벤트 발행 또는
  @TransactionalEventListener(phase = AFTER_COMMIT)로 커밋 후 FCM 발송
- FCM 실패가 원본 트랜잭션에 영향 없게 @Async 처리
- Notification DB 저장은 트랜잭션 내, FCM은 트랜잭션 외부

## 10. 위험과 대응

| 위험 | 대응 |
|---|---|
| PROOF_SUBMITTED에서 N건 INSERT (멤버 수만큼) | maxMembers 상한 있음. 허용 범위. |
| 단건 읽음에서 타인 notification 접근 | notification.getReceiver().getId() != currentUser.getId() → 403 |
| 이미 읽은 알림 단건 읽음 | readAt null 여부 확인 후 null일 때만 갱신. idempotent 200 반환. |
| read-all 성능 | receiver = currentUser AND readAt IS NULL 조건으로 벌크 업데이트 (@Modifying @Query) |
| 없는 알림 단건 읽음 | 404 반환 |
| confirmProof idempotent에서 PROOF_CONFIRMED 알림 중복 | 기존 confirmer 중복 확인(409)에서 차단됨. notify 도달 전 차단. |

## 11. 테스트 전략

Swagger 순서:
1. 방 생성 → 참여 → 예치 → 시작 → GET /api/notifications → ROOM_STARTED 알림 확인
2. 인증 제출 → 다른 멤버 GET /api/notifications → PROOF_SUBMITTED 알림 확인
3. 인증 확인 → 작성자 GET /api/notifications → PROOF_CONFIRMED 알림 확인
4. 정산 → GET /api/notifications → ROOM_SETTLED 알림 확인
5. GET /api/notifications/unread-count → 미읽음 수 확인
6. PUT /api/notifications/{id}/read → 단건 읽음 → unread-count 감소 확인
7. PUT /api/notifications/read-all → 전체 읽음 → unread-count = 0 확인
8. 타인 notification 읽음 → 403 확인
9. 없는 notification 읽음 → 404 확인

빌드: ./gradlew.bat clean build

## 12. 추천 결론

| 항목 | 결정 |
|---|---|
| 패키지 | domain/notification/ |
| Entity 필드 | id, receiver, room(nullable), type, title, message, readAt(nullable), BaseTime |
| 17단계 구현 타입 | PROOF_SUBMITTED / PROOF_CONFIRMED / ROOM_STARTED / ROOM_SETTLED (4종) |
| MEMBER_JOINED / MEMBER_STAKED | plan에서 포함 여부 확정 |
| API | GET /notifications, GET /notifications/unread-count, PUT /notifications/{id}/read, PUT /notifications/read-all |
| 정렬 | createdAt DESC, 최근 50건 |
| 읽음 처리 | readAt nullable. 단건 idempotent. 전체 @Modifying 벌크 업데이트 |
| 트랜잭션 | notify()는 호출부 트랜잭션 내. FCM은 18단계에서 트랜잭션 외부로 분리 |
| 연결 순서 | Activity.record() → Notification.notify() 순 |

plan에서 확정할 사항:
- MEMBER_JOINED / MEMBER_STAKED 알림 포함 여부 및 수신 대상
- title 문구 확정
- UnreadCountResponse DTO 구조 (단순 Long vs 객체)
- read-all 벌크 업데이트 쿼리 방식 확정
