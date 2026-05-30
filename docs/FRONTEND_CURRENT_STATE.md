# FRONTEND_CURRENT_STATE.md

이 문서는 Checkmate Flutter 프론트엔드의 현재 구현 상태를 이어받기 위한 기준 문서다.  
백엔드 구현 상태는 `docs/CURRENT_STATE.md`, API 정책은 `docs/03_API_SPEC.md`, 비즈니스 정책은 `docs/01_BUSINESS_RULES.md`를 함께 확인한다.

마지막 정리 기준: 2026-05-30  
대상: Flutter 프론트 (`flutter_checkmate`)

---

## 1. 프론트 역할

Checkmate 프론트는 Spring Boot 백엔드에 구현된 미션방 흐름을 모바일 앱 화면으로 연결한다.

```text
로그인 / 세션 복구
→ 내 방 목록
→ 방 생성 또는 초대 참여
→ 예치금 납부
→ 미션 시작 상태 확인
→ 인증 제출
→ 인증 피드에서 멤버 인증 확인
→ 멤버별 현황 조회
→ 정산 결과 확인
→ 알림 확인
→ 방 채팅
```

현재 프론트는 MVP 핵심 흐름과 2차 기능 일부까지 백엔드 API와 연결되어 있다.

---

## 2. 프로젝트 위치와 기술 스택

위치:
- 백엔드: `src/main/java/...`
- 프론트: `flutter_checkmate/lib/...`

기술 스택:

| 역할 | 사용 기술 |
|---|---|
| Framework | Flutter |
| 상태 관리 | flutter_riverpod |
| 라우팅 | go_router |
| HTTP Client | dio |
| 토큰 저장 | shared_preferences |
| 이미지 선택 | image_picker |
| Multipart | http_parser |
| 날짜/포맷 | intl |
| Firebase | firebase_core |
| Push 알림 | firebase_messaging |
| WebSocket/STOMP | stomp_dart_client |

앱 진입:
- `lib/main.dart`
- `ProviderScope`
- `MaterialApp.router`
- `appRouterProvider`

---

## 3. 프론트 구조

```text
lib/
├─ app/
│  ├─ app_router.dart
│  └─ app_container.dart
├─ core/
│  ├─ constants/
│  ├─ network/
│  ├─ providers/
│  ├─ storage/
│  ├─ theme/
│  └─ utils/
├─ models/
├─ screens/
├─ services/
└─ widgets/
```

연결 흐름:

```text
Screen
→ Riverpod Provider
→ Service
→ ApiClient(Dio)
→ Spring Boot API
→ Model.fromJson()
→ 화면 상태 갱신
```

---

## 4. 라우팅 상태

`lib/app/app_router.dart` 기준 현재 라우팅:

| 경로 | 화면 | 설명 |
|---|---|---|
| `/splash` | SplashScreen | 세션 복구 중 진입 화면 |
| `/login` | LoginScreen | 로그인 |
| `/signup` | SignupScreen | 회원가입 |
| `/home` | HomeScreen | 내 방 목록, 포인트, 알림 배지 |
| `/rooms/create` | CreateRoomScreen | 방 생성 |
| `/rooms/join` | JoinRoomScreen | 초대 링크/토큰 참여 |
| `/invite/:inviteLinkToken` | JoinRoomScreen | 초대 링크 진입 |
| `/rooms/:roomId` | RoomDashboardScreen | 방 상세 대시보드 |
| `/rooms/:roomId/members` | MemberStatusScreen | 멤버별 인증 현황 |
| `/rooms/:roomId/submit-proof` | SubmitProofScreen | 인증 제출 |
| `/rooms/:roomId/proofs` | ProofFeedScreen | 인증 피드 / 확인 |
| `/rooms/:roomId/chat` | RoomChatScreen | 방 채팅 |
| `/rooms/:roomId/settlement` | SettlementResultScreen | 정산 결과 |
| `/notifications` | NotificationScreen | 알림함 |
| `/mypage` | MyPageScreen | 마이페이지 |

라우팅 정책:
- 초기 경로는 `/splash`
- 인증되지 않은 사용자는 `/login`, `/signup`, `/invite/:inviteLinkToken` 외 접근 시 `/login`으로 이동
- 인증된 사용자가 `/login`, `/signup`, `/splash`에 접근하면 `/home`으로 이동
- roomId 파싱 실패 시 잘못된 방 주소 화면 표시

---

## 5. 인증과 API 연결

### 5.1 ApiClient

구현 파일:
- `core/network/api_client.dart`
- `core/constants/api_constants.dart`
- `core/storage/token_storage.dart`

baseUrl:
| 실행 환경 | baseUrl |
|---|---|
| Flutter Web | `http://localhost:8080` |
| Android Emulator | `http://10.0.2.2:8080` |
| 기타 | `http://localhost:8080` |
| 실제 휴대폰 | 코드 수정 또는 PC IPv4 기준 별도 설정 필요 |

Dio 설정:
- connectTimeout 5초
- receiveTimeout 5초
- 기본 contentType JSON
- signup/login은 Authorization 헤더 제외
- 나머지 API는 SharedPreferences의 accessToken을 읽어 `Authorization: Bearer {token}` 자동 첨부
- 401 발생 시 accessToken 삭제

에러 메시지:
- timeout
- statusCode
- connectionError
- unknown
순서로 사용자 친화적인 한국어 메시지 반환

---

### 5.2 Auth

구현 파일:
- `services/auth_service.dart`
- `core/providers/auth_controller.dart`
- `models/user_model.dart`

로그인:
1. `/api/users/login` 호출
2. accessToken 저장
3. FCM device token 등록 시도
4. `currentUser` 저장
5. 인증 상태를 authenticated로 변경

세션 복구:
1. 앱 시작 시 SharedPreferences accessToken 확인
2. 토큰이 있으면 `/api/users/me` 호출
3. 성공 시 currentUser 복구
4. FCM device token 재등록 시도
5. 실패 시 로컬 토큰 삭제 후 unauthenticated

로그아웃:
1. 현재 FCM token 비활성화 시도
2. 실패해도 로그아웃은 계속 진행
3. accessToken 삭제
4. 인증 상태를 unauthenticated로 변경

현재 구현 특징:
- FCM token 등록은 `auth_service.dart` 안에서 직접 처리한다.
- 별도 `device_token_service.dart`는 아직 없다.
- Web에서는 FCM device token 등록을 스킵한다.
- Android/iOS만 등록 대상이다.
- `onTokenRefresh` 자동 재등록은 미구현이며 다음 로그인/세션 복구 때 반영된다.

---

## 6. 화면별 구현 상태

### 6.1 Splash / Login / Signup

상태:
- 구현 완료

역할:
- Splash에서 세션 복구 진행
- Login 성공 시 token 저장 후 `/home` 이동
- Signup 성공 후 로그인 화면으로 이동

주의:
- 로그인/회원가입 API에는 Authorization 헤더를 붙이지 않는다.

---

### 6.2 HomeScreen

상태:
- 구현 완료

연결 API:
- `GET /api/rooms`
- `GET /api/points/me`
- `GET /api/notifications/unread-count`

구현 내용:
- 내가 참여 중인 방 목록 조회
- 보유 포인트 표시
- 앱 설명 카드 표시
- 방 카드에 예치금, 인증 방식, 목표 표시
- 알림 벨 unread badge 표시
- 알림함 복귀 후 unread count 재갱신
- 방 카드 클릭 시 `/rooms/:roomId` 이동

---

### 6.3 CreateRoomScreen

상태:
- 구현 완료

연결 API:
- `POST /api/rooms`

구현 내용:
- 방 제목, 설명, 기간, 마감 시간, 예치금, 인원, 인증 방식 입력
- DAILY: 30/60/90/120일 선택
- WEEKLY: 28/56/84/112일 선택
- WEEKLY 기간은 “4주(28일)” 형태로 표시
- 예치금 안내 카드 표시
- 인증 방식 안내 표시
- 생성 성공 시 방 상세로 이동

주의:
- 백엔드에서 durationDays, stakePoint, WEEKLY requiredProofCount 검증을 수행한다.

---

### 6.4 JoinRoomScreen

상태:
- 구현 완료

연결 API:
- `GET /api/rooms/invite/{inviteLinkToken}`
- `POST /api/rooms/{roomId}/join`

구현 내용:
- 초대 링크 또는 token 입력
- 전체 URL을 붙여넣어도 token만 추출
- 초대 미리보기 조회
- inviteCode 입력 후 방 참여
- 참여 안내 카드 표시
- `/invite/:inviteLinkToken` 라우트로 직접 진입 가능

---

### 6.5 RoomDashboardScreen

상태:
- 구현 완료

연결 API:
- `GET /api/rooms/{roomId}`
- `GET /api/rooms/{roomId}/members`
- `GET /api/rooms/{roomId}/today-status`
- `POST /api/rooms/{roomId}/stake`
- `POST /api/rooms/{roomId}/start`
- `POST /api/rooms/{roomId}/settle`
- `GET /api/rooms/{roomId}/settlement`

구현 내용:
- 방 상태 배지 표시
- 채팅 버튼 제공
- 미션 요약 카드
- 룰 안내 카드
- IN_PROGRESS 상태에서 today-status 조회
- 내 상태 카드
- 멤버별 현황 일부 표시
- 초대 코드/초대 링크 복사
- 상태별 하단 액션 버튼 표시

상태별 하단 액션:
| 방 상태 | 버튼 |
|---|---|
| RECRUITING | 예치금 납부 |
| READY + OWNER | 미션 시작 |
| READY + MEMBER | 시작 대기 |
| IN_PROGRESS | 인증 올리기 / 인증 확인하기 |
| 정산 가능 시점 | 정산하기 / 인증 확인하기 |
| SETTLED | 정산 결과 보기 |

정산 가능 시점 계산:
- 현재 날짜가 missionEndDate 이후면 가능
- missionEndDate 당일이면 deadlineTime 이후 가능
- 그 외에는 정산 버튼 숨김

---

### 6.6 SubmitProofScreen

상태:
- 구현 완료

연결 API:
- `POST /api/rooms/{roomId}/proofs`

구현 내용:
- content 입력
- 이미지/동영상 파일 선택
- content 또는 file 중 하나 이상 제출
- Dio FormData multipart 전송
- 409 에러 특화 메시지 표시
- 제출만으로 완료가 아니고 멤버 확인이 필요하다는 안내 표시

---

### 6.7 ProofFeedScreen

상태:
- 구현 완료

연결 API:
- `GET /api/rooms/{roomId}/proofs`
- `POST /api/proofs/{proofId}/confirm`

구현 내용:
- 인증 목록 조회
- 파일 URL이 상대경로면 `ApiConstants.baseUrl`을 붙여 표시
- 내 인증 여부 표시
- 이미 확인한 인증 여부 표시
- 확인 가능한 인증에만 확인 버튼 표시
- 확인 성공 시 silent refresh
- 빈 상태 / 로딩 / 에러 상태 처리

---

### 6.8 MemberStatusScreen

상태:
- 구현 완료

연결 API:
- `GET /api/rooms/{roomId}/members/stats`

구현 내용:
- 목표 달성 / 확인 대기 / 추가 필요 요약
- 멤버별 제출 수, 확인 완료 수, 필요 수 표시
- 진행률 바 표시
- `progressStatus ?? expectedResult ?? status` 순서로 상태 읽기
- CONFIRMED 기준으로 목표 달성 계산 안내

---

### 6.9 SettlementResultScreen

상태:
- 구현 완료

연결 API:
- `GET /api/rooms/{roomId}/settlement`

구현 내용:
- 정산 결과 조회
- 멤버별 성공/실패 결과 표시
- 제출 수, 확인 완료 수, 성공 기준, rewardPoint, proofRate 표시
- 전원 성공/일부 성공/전원 실패 정책에 맞춘 결과 표시

---

### 6.10 NotificationScreen

상태:
- 구현 완료

연결 API:
- `GET /api/notifications`
- `GET /api/notifications/unread-count`
- `PUT /api/notifications/{id}/read`
- `PUT /api/notifications/read-all`

구현 내용:
- 알림 목록 조회
- 전체/읽은 알림 필터
- 미읽음 알림 클릭 시 읽음 처리 후 이동
- 읽음 처리 실패 시 rollback
- 모두 읽음 처리
- roomId가 있으면 방 상세 이동
- roomId가 없으면 읽음 처리만 수행
- 타입별 emoji 표시
  - ROOM_STARTED
  - PROOF_SUBMITTED
  - PROOF_CONFIRMED
  - ROOM_SETTLED

---

### 6.11 RoomChatScreen

상태:
- 구현 완료

연결:
- REST: `GET /api/rooms/{roomId}/messages`
- STOMP endpoint: `/ws`
- subscribe: `/topic/rooms/{roomId}/messages`
- send: `/app/rooms/{roomId}/messages`

구현 내용:
1. 화면 진입 시 REST로 기존 메시지 조회
2. 조회 성공 후 STOMP 연결 시작
3. STOMP CONNECT에 Authorization Bearer token 포함
4. 연결 완료 전 메시지 전송 차단
5. 메시지 전송 시 로컬에 즉시 추가하지 않음
6. 서버 broadcast 수신 후 메시지 리스트에 추가
7. 화면 이탈 시 `disconnect()` 호출
8. 연결 중 / 연결 끊김 상태 바 표시
9. 내 메시지와 상대 메시지 말풍선 분리

주의:
- 실제 다중 클라이언트 STOMP 수신 테스트는 추가 확인 필요
- 채팅은 방 멤버 권한을 백엔드에서 최종 검증한다

---

### 6.12 MyPageScreen

상태:
- 구현 완료

역할:
- 사용자 정보 표시
- 로그아웃 진입점

---

## 7. 백엔드 응답과 맞춘 처리

### Room id 필드 혼재

백엔드 Room 응답에서 `id`와 `roomId`가 혼재한다.

| API | 응답 DTO | id 필드 |
|---|---|---|
| `POST /api/rooms` | RoomDetailResponse | `id` |
| `GET /api/rooms` | RoomSummaryResponse | `id` |
| `GET /api/rooms/{roomId}` | RoomDetailEnrichedResponse | `roomId` |

Flutter 모델 처리:
```dart
id: _readInt(json['roomId'] ?? json['id'])
```

정리:
- 백엔드 필드를 대규모로 바꾸지 않고, Flutter model에서 안전하게 흡수한다.
- `id`를 `roomId`로 일괄 변경하는 대규모 수정은 하지 않는다.

---

### Proof 파일 URL

백엔드가 `/uploads/proofs/{fileName}` 형태의 상대경로를 반환한다.

Flutter 처리:
- 상대경로면 `ApiConstants.baseUrl`을 앞에 붙인다.
- 이미 http로 시작하면 그대로 사용한다.

---

### Error Message

`ApiClient.messageFromError()` 기준:
- timeout은 별도 메시지
- statusCode가 있으면 400/401/403/404/409/413/500 기준 메시지
- 서버 응답이 없으면 연결 실패 메시지
- Dio 내부 문자열이나 긴 개발자용 메시지를 사용자에게 그대로 노출하지 않도록 처리

---

## 8. 백엔드 연결 검증 현황

완료:
- 회원가입 / 로그인 / 로그아웃
- 세션 복구
- 보유 포인트 조회
- 방 목록 조회
- 방 생성 후 상세 이동
- 방 참여
- 예치금 납부
- 방 시작
- 인증 제출
- 인증 피드 조회
- 인증 확인
- 멤버별 현황 조회
- 정산 결과 조회
- 알림 목록 조회
- 알림 읽음 처리
- 모두 읽음 처리
- 홈 unread badge 갱신
- Android 에뮬레이터 ROOM_STARTED FCM 수신
- device token 등록/비활성화
- RoomChatScreen 코드 연결

현재 알려진 오류:
- 기존 TypeError는 해결 완료
- 사용자 친화적 에러 메시지 처리 완료

추가 확인 필요:
- STOMP 다중 클라이언트 실시간 송수신
- FCM foreground/background 수신 처리
- push 클릭 시 이동
- ActivityFeedScreen
- MissionProgressBoard
- SettlementShareCardScreen

---

## 9. Firebase / FCM 프론트 상태

초기 설정 완료:
- Firebase CLI 로그인
- FlutterFire CLI 설치
- `flutterfire configure`
- `lib/firebase_options.dart` 생성
- `android/app/google-services.json` 추가
- Android/Web 초기화 확인
- Android 에뮬레이터 FCM token 발급 확인
- FCM 권한 `AuthorizationStatus.authorized` 확인

수정 파일:
- `pubspec.yaml`
- `lib/main.dart`
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`

DeviceToken 연결:
- 로그인 성공 후 `POST /api/device-tokens`
- 로그아웃 시 `DELETE /api/device-tokens`
- 세션 복구 성공 후 재등록
- Web은 스킵
- Android/iOS만 등록

검증:
- 로그인 후 `device_tokens.active=1`
- 로그아웃 후 `active=0`
- 재로그인 후 `active=1`

남은 점:
- `FirebaseMessaging.instance.onTokenRefresh` 미구현
- device token 관련 로직이 아직 `auth_service.dart` 안에 있음

---

## 10. 구현 순서 기준 진행 기록

### 1단계 — 기본 앱 구조
- Flutter 프로젝트 구성
- Riverpod Provider 구조 도입
- GoRouter 라우팅 구성
- AppContainer 적용
- Splash/Login/Signup/Home 기본 흐름 구성

### 2단계 — 백엔드 API 연결
- Dio 기반 ApiClient 구현
- SharedPreferences token 저장
- Authorization 자동 첨부
- baseUrl 실행 환경 분기
- 로그인/회원가입 공개 API 처리

### 3단계 — 방 기능 연결
- 방 목록 조회
- 방 생성
- 초대 링크/토큰 참여
- 방 상세 진입
- Room model null-safe 처리
- `id` / `roomId` 혼재 대응

### 4단계 — 예치와 미션 진행 화면
- RoomDashboardScreen 구성
- 예치금 납부
- 방 시작
- 미션 요약 카드
- 현재 인증 현황 카드
- 멤버별 현황 미리보기
- 정산 가능 시점 계산

### 5단계 — 인증 제출과 확인
- image_picker 연결
- Dio FormData multipart 업로드
- SubmitProofScreen
- ProofFeedScreen
- 인증 확인 버튼
- 파일 URL 상대경로 처리

### 6단계 — 멤버 현황과 정산 결과
- MemberStatusScreen
- SettlementResultScreen
- 성공/실패/보상 결과 표시
- 확인 완료 기준 안내 문구 정리

### 7단계 — 알림
- notification_model
- notification_service
- NotificationScreen
- 홈 unread badge
- 읽음 처리와 낙관적 업데이트
- roomId 기반 이동

### 8단계 — Firebase / FCM
- Firebase 초기화
- FCM token 발급
- 로그인 후 device token 등록
- 로그아웃 후 device token 비활성화
- 세션 복구 후 재등록

### 9단계 — 채팅
- ChatService
- ChatMessageModel
- RoomChatScreen
- REST 기존 메시지 조회
- STOMP 연결
- 메시지 전송/수신
- 연결 상태 표시
- 화면 이탈 시 disconnect

---

## 11. 다음 작업

우선순위:

1. RoomChatScreen 실기기 또는 Web 2개 클라이언트 송수신 확인
2. ActivityFeedScreen 구현
3. FCM foreground/background 처리
4. push 클릭 이동
5. MissionProgressBoard
6. SettlementShareCardScreen

---

## 12. 작업 시 주의사항

- 백엔드 API를 무작정 바꾸지 않는다.
- 백엔드 응답 필드를 바꾸기보다 Flutter model에서 흡수 가능한지 먼저 확인한다.
- `id`를 `roomId`로 일괄 변경하는 대규모 수정 금지.
- 코드 수정 전 변경 파일과 수정 내용을 먼저 제시한다.
- 기존 route를 변경하면 백엔드 알림 이동, 초대 링크, 화면 이동 흐름이 깨질 수 있다.
- FCM 실패가 로그인 실패로 이어지지 않도록 현재 구조를 유지한다.
- ChatService는 화면 dispose 시 반드시 disconnect해야 한다.
- 문서 수정 작업에서는 Flutter/Dart 코드를 함께 수정하지 않는다.
