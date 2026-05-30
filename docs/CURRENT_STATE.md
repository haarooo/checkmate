# CURRENT_STATE.md

이 문서는 Checkmate 백엔드의 현재 구현 상태를 이어받기 위한 기준 문서다.  
정책의 원본은 `docs/01_BUSINESS_RULES.md`, API 상세는 `docs/03_API_SPEC.md`를 기준으로 하고, 이 문서는 실제 코드 기준으로 지금 어디까지 구현되어 있는지를 정리한다.

마지막 정리 기준: 2026-05-30  
대상: Spring Boot 백엔드 (`src/main/java/com/example/checkmate`)

---

## 1. 서비스 흐름 기준

Checkmate의 백엔드는 아래 사용자 흐름을 중심으로 구현되어 있다.

```text
회원가입
→ 포인트 지갑 생성 / 가입 보너스 지급
→ 미션방 생성
→ 초대 링크 또는 초대 코드로 참여
→ 예치금 납부
→ 전원 예치 완료 시 READY
→ 방장 미션 시작
→ 다음 날부터 인증 제출
→ 멤버가 서로 인증 확인
→ 미션 종료 후 정산
→ 포인트 원장 반영
→ 알림 / FCM / 채팅으로 방 활동 보조
```

현재 MVP의 핵심 흐름은 **방 생성 → 참여 → 예치 → 시작 → 인증 → 확인 → 정산**까지 연결되어 있다.

---

## 2. 현재 구현 범위

| 영역 | 상태 | 주요 구현 |
|---|---|---|
| 사용자 / 인증 | 완료 | 회원가입, 로그인, JWT, Spring Security, `/api/users/me` |
| 포인트 | 완료 | PointWallet, PointLedger, 가입 보너스, 테스트 충전, 예치 차감, 정산 지급 |
| 방 | 완료 | 방 생성, 초대 링크, 참여, 멤버 조회, 예치, 시작 |
| 인증 | 완료 | 텍스트/파일 인증 제출, 인증 피드, 멤버 확인 |
| 현황 / 통계 | 완료 | 오늘 또는 이번 주 인증 현황, 멤버별 누적 통계 |
| 정산 | 완료 | 전원 성공, 일부 성공, 전원 실패 케이스 처리 |
| 활동 피드 | 완료 | 방 참여, 예치, 시작, 인증, 확인, 정산 이벤트 기록 |
| 알림 | 완료 | DB 알림, 읽음 처리, 읽지 않은 알림 수 |
| FCM | 완료 | 디바이스 토큰 등록/비활성화, AFTER_COMMIT 푸시 발송 |
| 파일 업로드 | 완료 | 로컬 저장, `/uploads/**` 정적 파일 제공 |
| 채팅 | 구현 완료 | REST 메시지 조회, STOMP 송수신, 멤버 권한 검증 |
| 문서 / 테스트 | 진행 중 | 주요 기능별 테스트 기록 작성, 문서와 코드 정합성 보정 중 |

---

## 3. 도메인별 현재 상태

### 3.1 User / Security

구현 파일:
- `domain/user`
- `global/security`

구현 내용:
- 회원가입 시 이메일 중복 검사, 비밀번호 암호화, `UserEntity` 저장
- 가입 완료 후 `PointWallet` 생성 및 `SIGNUP_BONUS 100,000P` 지급
- 로그인 시 `AuthenticationManager`로 인증 후 JWT accessToken 발급
- JWT subject는 email, role claim 포함
- `JwtAuthenticationFilter`가 `Authorization: Bearer {token}`을 검증하고 `SecurityContext`에 인증 객체 등록
- 공개 API:
  - `/api/users/signup`
  - `/api/users/login`
  - `/swagger-ui/**`
  - `/v3/api-docs/**`
  - `/error`
  - `/uploads/**`
  - `/ws/**`
  - `GET /api/rooms/invite/**`
- 그 외 API는 인증 필요

주의:
- WebSocket HTTP handshake는 `/ws/** permitAll`이지만, STOMP CONNECT 단계에서 별도 JWT 검증을 수행한다.

---

### 3.2 Point

구현 파일:
- `domain/point`

구현 내용:
- `PointWallet`: 사용자별 현재 포인트 잔액
- `PointLedger`: 포인트 증감 이력
- 회원가입 시 `SIGNUP_BONUS 100,000P`
- 테스트 충전 API 제공
- 예치금 납부 시:
  - wallet balance 차감
  - `ROOM_STAKE` 음수 원장 기록
  - roomId 연결
- 정산 시:
  - 예치금 반환: `ROOM_SETTLEMENT_REFUND`
  - 성공 보너스: `ROOM_SETTLEMENT_SUCCESS_BONUS`
  - 일부 성공 보상: `ROOM_SETTLEMENT_REWARD`
- `PointWallet`에 `@Version` 적용

현재 기준:
- 포인트 잔액 변경과 원장 기록을 함께 남기는 구조로 구현되어 있다.
- 예치/정산처럼 포인트가 움직이는 기능은 단순 balance update가 아니라 ledger 기록을 같이 남긴다.

---

### 3.3 Room

구현 파일:
- `domain/room`

방 상태 흐름:

```text
RECRUITING → READY → IN_PROGRESS → SETTLED
```

구현 내용:
- 방 생성 시 상태는 `RECRUITING`
- 생성자는 `OWNER`로 `room_members`에 등록
- `inviteCode`: 6자, 방 참여 검증용
- `inviteLinkToken`: 32자, 초대 링크 미리보기용
- 참여자는 `MEMBER`로 등록
- `(room_id, user_id)` 유니크 제약으로 중복 참여 방지
- 예치금 납부 시 `RoomMember.status = STAKED`
- 전원 참여 + 전원 예치 완료 시 `Room.status = READY`
- 방장만 미션 시작 가능
- 시작 시 `missionStartDate = Asia/Seoul 기준 오늘 + 1일`
- `missionEndDate = missionStartDate + durationDays - 1일`

방 생성 검증:
- `durationDays < 28`이면 400
- `stakePoint < 1,000` 또는 `stakePoint > 50,000`이면 400
- `WEEKLY`는 `durationDays`가 7의 배수여야 함
- `WEEKLY`는 `requiredProofCount <= 7`
- `DAILY`는 `requiredProofCount >= 1`이면 허용
- 현재 `targetRate`는 80으로 고정

예치금 납부:
- `findByIdForUpdate(roomId)`로 방 row 비관적 락
- 잔액 부족 400
- 비멤버 403
- 이미 예치한 멤버 409
- 모집 중이 아닌 방 409
- 전원 예치 완료 시 `READY` 자동 전환

---

### 3.4 Proof

구현 파일:
- `domain/proof`
- `global/storage`

인증 제출:
- `POST /api/rooms/{roomId}/proofs`
- `multipart/form-data`
- `content` 또는 `file` 중 하나 필수
- 텍스트만, 파일만, 텍스트+파일 모두 허용
- 방 멤버만 제출 가능
- `IN_PROGRESS` 방에서만 제출 가능
- 미션 기간 내에서만 제출 가능
- `deadlineTime` 이후 제출 불가
- `deadlineTime` 정각은 허용, 이후만 차단
- 제출 시 최초 상태는 `SUBMITTED`

제출 횟수 기준:
- `DAILY`: 같은 방 + 같은 사용자 + 같은 날짜 제출 수가 `requiredProofCount` 미만이면 가능
- `WEEKLY`: Asia/Seoul 기준 월~일 주차 내 제출 수가 `requiredProofCount` 미만이면 가능

파일 저장:
- 저장 위치: `uploads/proofs/`
- 파일명: UUID + 확장자
- 허용 확장자:
  - 이미지: `jpg`, `jpeg`, `png`, `gif`, `webp`
  - 동영상: `mp4`, `mov`, `webm`
- `/uploads/**` 정적 파일 접근 허용

인증 확인:
- `POST /api/proofs/{proofId}/confirm`
- 방 멤버만 가능
- 본인 인증 확인 불가
- 같은 사용자의 중복 확인 불가
- 최초 확인 시 `Proof.status = CONFIRMED`
- `confirmedAt`은 최초 확인 시점으로 고정
- 이미 `CONFIRMED`인 proof에 다른 멤버가 확인하면 200으로 처리하되 최초 `confirmedAt`은 유지

인증 피드:
- `GET /api/rooms/{roomId}/proofs`
- createdAt DESC 정렬
- 응답에 `canConfirm`, `isMine`, `alreadyConfirmedByMe`, `confirmationCount`, `requiredConfirmationCount(1)` 포함

---

### 3.5 Today Status / Member Stats

구현 파일:
- `TodayStatusService`
- `MemberStatsService`

오늘 또는 현재 주차 현황:
- `GET /api/rooms/{roomId}/today-status`
- `IN_PROGRESS` + 미션 기간 내에서만 조회 가능
- DAILY는 오늘 기준
- WEEKLY는 이번 주 월~일 기준
- 멤버별 제출 수, 확인 완료 수, 상태 제공
- 응답 상태:
  - `SUCCESS`
  - `WAITING_CONFIRM`
  - `NEED_SUBMIT`
  - `MISSED`

전체 누적 통계:
- `GET /api/rooms/{roomId}/members/stats`
- `IN_PROGRESS`, `SETTLED` 방에서 조회 가능
- `RECRUITING`, `READY`는 409
- 성공 인증은 `CONFIRMED`만 계산
- `totalRequiredProofCount`
  - DAILY: `durationDays * requiredProofCount`
  - WEEKLY: `(durationDays / 7) * requiredProofCount`
- `requiredSuccessCount = ceil(totalRequiredProofCount * targetRate / 100.0)`
- 응답용 expectedResult:
  - `SUCCESS`
  - `WAITING_CONFIRM`
  - `NEED_MORE`
  - `FAILED`

---

### 3.6 Settlement

구현 파일:
- `domain/settlement`
- `domain/point`
- `domain/room`

정산 실행:
- `POST /api/rooms/{roomId}/settle`
- 방 멤버 누구나 실행 가능
- `findByIdForUpdate(roomId)`로 방 row 비관적 락
- `IN_PROGRESS` 방만 정산 가능
- 이미 정산된 방은 409
- 정산 가능 시점:
  - `today > missionEndDate`이면 가능
  - `today == missionEndDate && nowTime > deadlineTime`이면 가능
  - 그 외에는 409
- 성공 여부는 `CONFIRMED` 인증 개수로 계산

정산 케이스:

| 케이스 | 처리 |
|---|---|
| 전원 성공 | 각자 예치금 반환 + `stakePoint * 30 / 100` 성공 보너스 |
| 일부 성공 | 성공자 예치금 반환 + 실패자 예치금 분배 |
| 전원 실패 | 전체 potPoint의 30% systemFee 기록 + 나머지 70% 균등 환불 |

정산 후 변경:
- `Settlement` 저장
- `SettlementMember` 저장
- `PointWallet` 증가
- `PointLedger` 양수 이력 저장
- `RoomMember.status = SUCCESS / FAILED`
- `Room.status = SETTLED`
- `ROOM_SETTLED` 활동 기록
- 전 멤버 대상 `ROOM_SETTLED` 알림 생성

---

### 3.7 Room Activity

구현 파일:
- `domain/activity`

역할:
- 방 안에서 발생한 주요 이벤트를 최신순으로 조회하기 위한 피드

기록 이벤트:
- `MEMBER_JOINED`
- `MEMBER_STAKED`
- `ROOM_READY`
- `ROOM_STARTED`
- `PROOF_SUBMITTED`
- `PROOF_CONFIRMED`
- `ROOM_SETTLED`

조회:
- `GET /api/rooms/{roomId}/activities`
- 방 멤버만 조회 가능
- 최신순 50건
- `ROOM_READY`, `ROOM_SETTLED`는 actor null 시스템 이벤트

주의:
- `RoomActivity`는 방 안 활동 기록이다.
- `Notification`과 역할이 다르다.
- 방 참여, 예치금 납부는 `RoomActivity`에는 기록되지만 FCM 알림 대상은 아니다.

---

### 3.8 Notification / FCM / DeviceToken

구현 파일:
- `domain/notification`
- `domain/device`
- `domain/fcm`
- `global/config/FirebaseConfig`

NotificationType:
- `PROOF_SUBMITTED`
- `PROOF_CONFIRMED`
- `ROOM_STARTED`
- `ROOM_SETTLED`

DB 알림:
- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PUT /api/notifications/{notificationId}/read`
- `PUT /api/notifications/read-all`
- 단건 읽음 처리는 idempotent
- 전체 읽음 처리는 JPQL bulk update

FCM 구조:
- `NotificationService.notify()`
  - Notification 저장
  - `NotificationFcmEvent` 발행
- `NotificationFcmEventListener`
  - `@TransactionalEventListener(AFTER_COMMIT)`
  - 트랜잭션 커밋 이후 active token 순회 발송
- DB 롤백 시 FCM이 먼저 발송되는 문제를 방지

FCM 발송 대상:
- `ROOM_STARTED`: 전 멤버
- `PROOF_SUBMITTED`: 제출자 제외 전 멤버
- `PROOF_CONFIRMED`: 인증 작성자
- `ROOM_SETTLED`: 전 멤버

DeviceToken:
- `POST /api/device-tokens`
  - 신규 등록
  - 같은 token + 같은 user 재활성화
  - 같은 token + 다른 user 재할당
- `DELETE /api/device-tokens`
  - request body `{ "token": "..." }`
  - row 삭제가 아니라 active=false
- 무효 FCM token:
  - `UNREGISTERED`
  - `INVALID_ARGUMENT`
  - 위 응답 시 active=false 처리
  - `REQUIRES_NEW` 별도 트랜잭션으로 비활성화

주의:
- `POST /api/dev/fcm/send`는 개발 확인용 API다.
- 현재 인증은 필요하지만 dev profile 제한 또는 삭제는 아직 남은 작업이다.

---

### 3.9 Chat

구현 파일:
- `domain/chat`
- `global/websocket`

REST:
- `GET /api/rooms/{roomId}/messages`
- 방 멤버만 조회 가능
- 최근 50건을 DESC로 가져온 뒤 서비스에서 reverse하여 ASC로 반환

STOMP:
- endpoint: `/ws`
- send: `/app/rooms/{roomId}/messages`
- subscribe: `/topic/rooms/{roomId}/messages`
- SockJS 미사용

인증:
- WebSocket handshake는 `/ws/** permitAll`
- STOMP CONNECT에서 `Authorization: Bearer {token}` 검증
- `StompChannelInterceptor`가 JWT 검증 후 Principal에 email 등록
- 메시지 전송 시 `principal.getName()`으로 사용자 조회
- 방 멤버가 아니면 저장 및 broadcast 불가

저장:
- `RoomMessage`
  - room FK
  - sender FK
  - content TEXT
  - createdAt

MVP 제외:
- 이미지 메시지
- 메시지 수정/삭제
- 읽음 처리
- 타이핑 표시
- 채팅 푸시 알림
- 안 읽은 메시지 수

현재 상태:
- 백엔드 코드 구현 완료
- STOMP 통합 테스트는 별도 확인 필요

---

## 4. API 기준 정리

### User / Auth

| Method | URL | 설명 |
|---|---|---|
| POST | `/api/users/signup` | 회원가입 |
| POST | `/api/users/login` | 로그인 |
| GET | `/api/users/me` | 내 정보 조회 |

### Point

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/points/me` | 내 포인트 잔액 |
| GET | `/api/points/me/ledgers` | 내 포인트 이력 |
| POST | `/api/points/test/charge` | 테스트 충전 |

### Room

| Method | URL | 설명 |
|---|---|---|
| POST | `/api/rooms` | 방 생성 |
| GET | `/api/rooms` | 내가 속한 방 목록 |
| GET | `/api/rooms/{roomId}` | 방 상세 |
| GET | `/api/rooms/invite/{inviteLinkToken}` | 초대 링크 미리보기 |
| POST | `/api/rooms/{roomId}/join` | 방 참여 |
| GET | `/api/rooms/{roomId}/members` | 방 멤버 목록 |
| POST | `/api/rooms/{roomId}/stake` | 예치금 납부 |
| POST | `/api/rooms/{roomId}/start` | 미션 시작 |

### Proof / Status / Settlement

| Method | URL | 설명 |
|---|---|---|
| POST | `/api/rooms/{roomId}/proofs` | 인증 제출 |
| GET | `/api/rooms/{roomId}/proofs` | 인증 피드 |
| POST | `/api/proofs/{proofId}/confirm` | 인증 확인 |
| GET | `/api/rooms/{roomId}/today-status` | 현재 기간 인증 현황 |
| GET | `/api/rooms/{roomId}/members/stats` | 멤버별 누적 통계 |
| POST | `/api/rooms/{roomId}/settle` | 정산 실행 |
| GET | `/api/rooms/{roomId}/settlement` | 정산 결과 조회 |

### Activity / Notification / FCM / Chat

| Method | URL | 설명 |
|---|---|---|
| GET | `/api/rooms/{roomId}/activities` | 방 활동 피드 |
| GET | `/api/notifications` | 내 알림 목록 |
| GET | `/api/notifications/unread-count` | 읽지 않은 알림 수 |
| PUT | `/api/notifications/{notificationId}/read` | 단건 읽음 처리 |
| PUT | `/api/notifications/read-all` | 전체 읽음 처리 |
| POST | `/api/device-tokens` | FCM token 등록 |
| DELETE | `/api/device-tokens` | FCM token 비활성화 |
| POST | `/api/dev/fcm/send` | 개발용 FCM 수동 발송 |
| GET | `/api/rooms/{roomId}/messages` | 채팅 메시지 조회 |
| STOMP | `/app/rooms/{roomId}/messages` | 채팅 메시지 전송 |
| STOMP | `/topic/rooms/{roomId}/messages` | 채팅 메시지 구독 |

---

## 5. 구현 순서 기준 진행 기록

### 0단계 — 기본 인증과 포인트 기반 구축
- 회원가입 / 로그인 / JWT / Spring Security 구성
- Swagger/OpenAPI 설정
- `GET /api/users/me`
- PointWallet / PointLedger 생성
- 회원가입 보너스 100,000P 지급
- 포인트 잔액/원장 조회
- 테스트 충전 API 구현

### 1단계 — 방 생성과 초대 구조
- 방 생성 API 구현
- `inviteCode`, `inviteLinkToken` 분리
- 방장 OWNER 등록
- 방 목록/상세/초대 미리보기 구현
- 방 생성 검증 추가

### 2단계 — 방 참여와 예치금 납부
- 초대 코드 기반 방 참여
- 방 멤버 목록 조회
- 예치금 납부 구현
- 포인트 차감과 ROOM_STAKE 원장 기록
- 전원 예치 완료 시 READY 자동 전환
- stakeRoom 통합 테스트 작성 및 통과

### 3단계 — 미션 시작과 인증 주기
- 방장만 READY 방 시작 가능하도록 구현
- 미션 시작일을 다음 날로 설정
- DAILY/WEEKLY 인증 주기 도입
- requiredProofCount 검증 추가

### 4단계 — 파일 업로드와 인증 제출
- LocalFileStorageService 구현
- `/uploads/**` 정적 파일 서빙
- multipart 인증 제출 구현
- content/file 중 하나 필수
- 제출 수 제한 및 deadlineTime 검증 추가

### 5단계 — 인증 확인과 인증 피드
- 멤버 간 인증 확인 구현
- 본인 확인 금지, 중복 확인 방지
- Proof status CONFIRMED 전환
- 인증 피드 조회 구현
- canConfirm, isMine, alreadyConfirmedByMe 응답 추가

### 6단계 — 인증 현황과 누적 통계
- today-status 구현
- member stats 구현
- CONFIRMED 기준 성공률 계산
- DAILY/WEEKLY 기준 목표 수 계산

### 7단계 — 정산
- Settlement / SettlementMember 도메인 구현
- 전원 성공 / 일부 성공 / 전원 실패 분기 처리
- PointWallet / PointLedger 정산 반영
- RoomMember SUCCESS / FAILED 전환
- Room SETTLED 전환
- 정산 테스트 및 스모크 테스트 수행

### 8단계 — 조회 지원과 MVP 흐름 검증
- 방 상세 응답 확장
- settlement 결과 조회
- User A / User B 전체 플로우 검증
- 일부 성공 정산 케이스 검증

### 9단계 — 활동 피드
- RoomActivity 도메인 추가
- 방 참여, 예치, READY, 시작, 인증 제출, 인증 확인, 정산 이벤트 기록
- 활동 피드 조회 API 구현

### 10단계 — 알림과 FCM
- Notification 도메인 추가
- 알림 목록, unread count, 읽음 처리 구현
- DeviceToken 등록/비활성화 구현
- Firebase Admin SDK 초기화
- AFTER_COMMIT FCM 발송 구조 구현
- 무효 token 자동 비활성화 구현

### 11단계 — 채팅
- RoomMessage 도메인 추가
- REST 최근 메시지 조회 구현
- WebSocket/STOMP 설정
- STOMP CONNECT JWT 인증
- 방 멤버만 메시지 전송 가능하도록 검증

---

## 6. 테스트 및 검증 현황

완료된 검증:
- 회원가입 / 로그인 / JWT 인증 흐름 확인
- 방 생성, 초대, 참여 확인
- 예치금 납부 통합 테스트 완료
- 전원 예치 완료 시 READY 자동 전환 확인
- 방 시작 검증 완료
- Proof Submit 검증 완료
- Proof Confirm 검증 완료
- Today Status 검증 완료
- Member Stats 검증 완료
- Settlement 3가지 케이스 검증 완료
- Query Support 검증 완료
- Proof Feed 백엔드 구현 및 Flutter 연결 확인
- Room Activity Feed 검증 완료
- Notification DB/API 검증 완료
- DeviceToken DB/API 검증 완료
- Firebase Admin SDK + FCM 발송 확인
- Android 에뮬레이터 FCM 수신 확인
- MVP 전체 플로우 스모크 테스트 완료

대표 스모크 테스트:
```text
User A / User B
방 생성 → 초대 → 참여 → 예치 → 시작 → 인증 제출 → 인증 확인 → 정산 → 포인트 원장 확인
```

일부 성공 정산 확인:
```text
A SUCCESS, rewardPoint 2,000P
B FAILED, rewardPoint 0P
A 최종 101,000P
B 최종 99,000P
```

추가 확인 필요:
- STOMP 통합 테스트
- `/api/dev/fcm/send` dev profile 제한 또는 삭제
- 채팅 메시지 실제 다중 클라이언트 수신 검증
- 배포 환경에서 업로드 파일 저장 방식 전환 검토

---

## 7. 현재 남은 작업

우선순위 기준:

1. Room Chat STOMP 통합 테스트
   - 정상 token CONNECT
   - 잘못된 token CONNECT 거부
   - 구독 후 SEND 시 DB 저장 및 broadcast 수신
   - 비멤버 SEND 차단

2. Flutter RoomChatScreen 최종 연결 확인
   - 기존 메시지 조회
   - STOMP 연결 상태 표시
   - 메시지 송수신
   - 화면 이탈 시 disconnect

3. ActivityFeedScreen
   - 백엔드 API는 구현 완료
   - Flutter 화면은 후보 상태

4. FCM foreground/background 처리
   - 포그라운드 수신
   - 백그라운드/종료 상태 수신
   - push 클릭 이동

5. Mission Progress Board
   - 방 전체 진행률 대시보드 확장

6. Settlement Share Card
   - 개인/그룹 정산 결과 카드 UI
   - 이미지 저장/공유 기능은 후순위

---

## 8. 작업 시 주의사항

- 위 기능을 처음부터 다시 만들지 않는다.
- 정책이 헷갈리면 `01_BUSINESS_RULES.md`와 실제 Service 코드를 함께 확인한다.
- API 문서가 실제 Controller/Service와 다르면 실제 구현 기준으로 판단한다.
- `SecurityConfig`, `JwtAuthenticationFilter`, `JwtTokenProvider`는 전체 인증 흐름에 영향이 있으므로 대규모 수정 금지.
- `Room.status` 흐름을 임의로 바꾸지 않는다.
- `RoomMemberStatus.SETTLED`는 레거시 값으로 남아 있으나 현재 미사용이다.
- 정산 로직은 포인트 원장과 직접 연결되므로 수정 전 반드시 테스트 케이스를 먼저 정리한다.
- FCM 발송은 Notification 저장 후 AFTER_COMMIT 이벤트 구조를 유지한다.
- 로컬 파일 저장은 MVP 개발용이며 운영 전 S3 또는 외부 스토리지 전환을 검토한다.
- 문서 수정 작업에서는 Java/Dart 코드를 함께 수정하지 않는다.
