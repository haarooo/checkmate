# 15_second_phase_plan.md

## 1. 2차 기능 목표

Checkmate MVP는 방 생성 → 초대 → 예치 → 인증 제출/확인 → 정산의
핵심 루프를 완성했다.

MVP에서 완성된 핵심 흐름:
- 가상 포인트 예치 기반 인증방 생성
- 친구 초대 → 전원 예치 → 방장 시작
- 텍스트/이미지/동영상 인증 제출 → 멤버 확인
- 목표 인증률 기준 자동 정산 (3케이스)
- 인증 피드, 오늘 현황, 멤버 통계 조회

2차 기능에서 추가할 사용자 경험:
- 방 안에서 일어난 일을 활동 피드로 확인한다.
- 인증 제출/확인/시작 같은 이벤트를 앱 알림과 푸시로 받는다.
- 방 멤버끼리 실시간으로 채팅한다.
- 나와 멤버의 미션 진행 상태를 한눈에 본다.
- 정산 결과를 카드 형태로 확인하고 공유한다.

---

## 2. 2차 기능 전체 방향

| 기능 | 핵심 |
|------|------|
| 방 활동 피드 | 방 이벤트 7종 자동 기록, 타임라인 조회 |
| 알림 + FCM 푸시 | DB 알림함 + 외부 FCM 푸시 이원화 |
| WebSocket/STOMP 채팅 | 실시간 채팅, 이전 메시지 REST 조회 |
| 미션 진행보드 고도화 | 방 전체 진행률 대시보드 시각화 |
| 정산 결과 공유 카드 | 개인/그룹 결과 카드 화면 |

---

## 3. 방 활동 피드 (16단계)

### 목표
방에서 발생한 이벤트를 자동으로 기록하고 멤버가 타임라인으로 조회한다.

### 기록할 이벤트 (ActivityType)
- MEMBER_JOINED: 멤버 참여
- MEMBER_STAKED: 예치금 납부
- ROOM_READY: 전원 예치 완료 (READY 전환)
- ROOM_STARTED: 방 시작
- PROOF_SUBMITTED: 인증 제출
- PROOF_CONFIRMED: 인증 확인
- ROOM_SETTLED: 정산 완료

### 필요한 이유
- 방에 들어왔을 때 그동안 무슨 일이 있었는지 파악 가능
- 알림/FCM 단계에서 활동 이벤트를 소스로 활용 가능
- 채팅과 달리 시스템 자동 기록이므로 누락 없음

### RoomActivity 설계 초안
```
room_activities
- id
- room_id FK
- actor_id FK NULL  (시스템 이벤트는 null 가능)
- type (ActivityType enum)
- message (표시 문구, 예: "홍길동님이 방에 참여했습니다.")
- created_at
```

### API 후보
- GET `/api/rooms/{roomId}/activities`
  - 방 멤버만 조회. 비멤버 403.
  - createdAt DESC 정렬 (최신 먼저)
  - 페이지네이션 또는 최근 N건 (plan에서 확정)

### 연결될 기존 서비스 후보
- RoomService.joinRoom() → MEMBER_JOINED
- RoomService.stakeRoom() → MEMBER_STAKED, ROOM_READY
- RoomService.startRoom() → ROOM_STARTED
- ProofService.submitProof() → PROOF_SUBMITTED
- ProofService.confirmProof() → PROOF_CONFIRMED
- SettlementService.settle() → ROOM_SETTLED

---

## 4. 알림 + FCM 푸시 (17~18단계)

### 구현 방향
Notification DB(앱 내 알림함) 먼저 구축하고,
이후 DeviceToken + FCM(외부 푸시)을 추가한다.

### Notification DB가 먼저 필요한 이유
- FCM은 토큰이 없거나 실패해도 알림함에는 기록되어야 함
- FCM 실패가 원본 이벤트 처리 실패로 이어지면 안 됨
- 앱 내 알림함은 FCM과 무관하게 독립 동작해야 함

### Notification 설계 초안
```
notifications
- id
- receiver_id FK
- room_id FK NULL
- type (PROOF_SUBMITTED / PROOF_CONFIRMED / ROOM_STARTED / ROOM_SETTLED / MEMBER_JOINED / MEMBER_STAKED)
- title
- message
- read_at NULL
- created_at
```

### DeviceToken 설계 초안
```
device_tokens
- id
- user_id FK
- token UNIQUE
- platform (ANDROID / IOS / WEB)
- active
- created_at
- updated_at
```

### FCM 발송 흐름
1. 이벤트 발생 → Notification DB 저장 (트랜잭션 내)
2. 트랜잭션 커밋 후 FCM 발송 시도 (트랜잭션 외부 또는 비동기)
3. FCM 실패 → 로그만 기록, 원본 응답에 영향 없음

### FCM 실패 처리 원칙
- FCM 발송은 @Async 또는 트랜잭션 완료 후 처리
- FCM 실패 시 RuntimeException을 상위로 전파하지 않음
- Notification DB 저장은 FCM 성공 여부와 무관하게 유지

### 알림 대상 규칙
| 이벤트 | 대상 |
|--------|------|
| 인증 제출 | 작성자 제외 방 멤버 |
| 인증 확인 | 인증 작성자 |
| 방 시작 | 방 멤버 전체 |
| 정산 완료 | 방 멤버 전체 |

### API 후보
- GET `/api/notifications`
- GET `/api/notifications/unread-count`
- PUT `/api/notifications/{notificationId}/read`
- PUT `/api/notifications/read-all`
- POST `/api/device-tokens`
- DELETE `/api/device-tokens/{token}`

---

## 5. WebSocket/STOMP 실시간 채팅 (19단계)

### 처음부터 STOMP로 가는 이유
- 순수 WebSocket은 직접 메시지 라우팅 구현 필요
- STOMP는 pub/sub 구조가 내장되어 방별 채널 분리가 자연스러움
- Spring WebSocket + STOMP 조합이 Spring Boot 표준 패턴
- Flutter stomp_dart_client 패키지로 연동 가능

### 백엔드 기술 후보
- Spring WebSocket + STOMP (`spring-boot-starter-websocket`)
- SimpMessagingTemplate으로 메시지 브로드캐스트
- @MessageMapping, @SendTo 어노테이션 활용
- 방 멤버 권한 검증: ChannelInterceptor 또는 메시지 핸들러 내부 검증

### Flutter 기술 후보
- `stomp_dart_client` 패키지
- WebSocket 연결: `ws://host/ws`
- SUBSCRIBE: `/topic/rooms/{roomId}/messages`
- SEND: `/app/rooms/{roomId}/messages`

### RoomMessage 설계 초안
```
room_messages
- id
- room_id FK
- sender_id FK
- content (빈 문자열 불가)
- created_at
```

### REST API 후보
- GET `/api/rooms/{roomId}/messages`
  - 방 멤버만, 비멤버 403
  - createdAt ASC 또는 커서 기반 페이지네이션 (plan에서 확정)

### WebSocket endpoint
- `/ws` (SockJS fallback 고려)

### STOMP destination
- SUBSCRIBE: `/topic/rooms/{roomId}/messages`
- SEND: `/app/rooms/{roomId}/messages`

### 채팅 처리 흐름
1. Flutter → STOMP SEND `/app/rooms/{roomId}/messages` (content 전송)
2. 백엔드 @MessageMapping → RoomMessage DB 저장
3. SimpMessagingTemplate → `/topic/rooms/{roomId}/messages` 브로드캐스트
4. 구독 중인 모든 방 멤버 클라이언트 수신

### 제외 범위
- 메시지 삭제/수정
- 채팅 이미지 업로드
- 채팅 읽음 처리 (read_at, 안 읽은 수)
- FCM topic 구독 방식

---

## 6. 미션 진행보드 고도화 (20단계)

### 현재 파란 요약 카드와 2차 진행보드의 차이
- 현재: 내 제출/확인/남은 제출 3개 숫자 + 멤버 미리보기 3명
- 2차: 방 전체 인원 진행 상태를 한눈에 보는 대시보드

### 방 전체 진행 상태 대시보드 목표
- 전체 멤버 중 목표 달성 / 확인 대기 / 추가 필요 인원 분포
- 멤버별 진행률 시각화 (확인 완료 / 목표까지 남은 수)
- 현재 기간 마감까지 남은 시간

### 보여줄 정보
- 방 전체 달성률 (confirmed 합계 / totalRequired)
- 멤버별 progressStatus + 진행 수치
- 목표 달성 인원 / 전체 인원

### 기존 today-status / members-stats 활용 방향
- `/api/rooms/{roomId}/today-status`: 현재 기간 내 실시간 현황
- `/api/rooms/{roomId}/members/stats`: 전체 기간 누적 통계
- 초기에는 두 API 재사용, 추후 progress-board 전용 API 후보

### 추후 progress-board API 후보
- GET `/api/rooms/{roomId}/progress-board`
  - today-status + members-stats 통합 응답
  - 방 전체 달성률 추가

---

## 7. 정산 결과 공유 카드 (21단계)

### 목표
정산 완료 후 내 결과와 방 전체 결과를 카드 형태로 확인한다.

### 개인 카드 예시
```
[홍길동]
미션 결과: 성공
확인 완료: 45 / 56회
달성률: 80.4%
예치금: 10,000P
보상: 12,500P (+2,500P)
```

### 그룹 카드 예시
```
[여름 전까지 4주 운동방]
정산 완료 2026.05.23
성공: 2명 / 실패: 1명
총 예치금: 30,000P
```

### 초기 구현 방향
- GET `/api/rooms/{roomId}/share-card/me`: 개인 결과 카드 데이터
- GET `/api/rooms/{roomId}/share-card/group`: 그룹 결과 카드 데이터
- Flutter 화면에서 카드 UI로 표시
- 기존 settlement + settlementMember 데이터 활용

### 추후 이미지 저장/공유 확장 방향
- Flutter screenshot 기반 카드 이미지 저장
- 외부 SNS 공유는 Post-MVP 범위

---

## 8. 추천 구현 순서

1. **방 활동 피드 (16단계)**
   - 의존성 없음. 기존 서비스에 기록만 추가.
   - 이후 알림/채팅의 이벤트 소스로 활용.

2. **Notification DB + 알림함 API (17단계)**
   - FCM 없이 알림 저장/조회 구조 먼저 확보.
   - FCM 실패 시에도 알림함은 독립 동작 보장.

3. **DeviceToken + FCM 발송 (18단계)**
   - Notification 구조가 있어야 발송 후 저장 연결 가능.
   - 비동기/트랜잭션 분리 패턴 적용.

4. **WebSocket/STOMP 채팅 (19단계)**
   - 별도 인프라(STOMP 브로커) 추가 필요.
   - 알림/활동 피드와 독립적으로 구성 가능.

5. **미션 진행보드 고도화 (20단계)**
   - 기존 API 재활용으로 백엔드 부담 최소.
   - 프론트 집중 단계.

6. **정산 결과 공유 카드 (21단계)**
   - 정산 완료 후 데이터 읽기 전용.
   - 기존 settlement 데이터 활용, 신규 API 최소화.

---

## 9. 2차 MVP 범위

### 2차 MVP 1차 범위 (16~19단계)
- RoomActivity 활동 피드
- Notification DB + 알림함 API
- DeviceToken + FCM 발송 기반
- WebSocket/STOMP 실시간 채팅

### 2차 MVP 2차 범위 (20~21단계)
- 미션 진행보드 고도화
- 정산 결과 공유 카드

---

## 10. 제외 범위

- 메시지 삭제/수정
- 채팅 이미지 업로드
- 채팅 읽음 처리 (read_at, 안 읽은 수)
- 관리자 신고/제재
- FCM topic 구독 방식
- iOS 실제 배포 설정
- 앱스토어/플레이스토어 배포
- 정산 결과 이미지 저장
- 외부 SNS 직접 공유

---

## 11. 다음 작업

1. `docs/research/16_room_activity_research.md` 작성
2. `docs/plans/16_room_activity_plan.md` 작성
3. 승인 후 RoomActivity Entity / ActivityType / 기록 로직 구현
4. GET `/api/rooms/{roomId}/activities` 구현 및 Swagger 테스트
5. CURRENT_STATE.md 갱신
6. 이후 17단계(Notification DB + API)로 진행
