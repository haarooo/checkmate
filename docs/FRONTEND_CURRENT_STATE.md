# FRONTEND_CURRENT_STATE.md

마지막 업데이트: 2026-05-25

---

## 1. 프론트 위치

- Flutter 프론트 폴더: `flutter_checkmate`
- 백엔드 Spring Boot 폴더와 같은 `checkmate` 루트 안에 있음
- 백엔드: `src/main/java/...`
- 프론트: `flutter_checkmate/lib/...`

---

## 2. Flutter 기술 스택

`pubspec.yaml` 기준:

| 항목 | 패키지 |
|------|--------|
| Framework | Flutter |
| 상태관리 | flutter_riverpod |
| 라우팅 | go_router |
| HTTP Client | dio |
| 토큰 저장 | shared_preferences |
| 이미지 업로드 | image_picker |
| Multipart 지원 | http_parser |
| 날짜/포맷 | intl |
| Firebase Core | firebase_core |
| Push 알림 | firebase_messaging |

---

## 3. 핵심 진입 구조

- 진입점: `flutter_checkmate/lib/main.dart`
- `ProviderScope`로 앱 시작
- `MaterialApp.router` 사용
- `appRouterProvider` 사용

---

## 4. 라우팅 구조

`lib/app/app_router.dart` 기준:

| 경로 | 화면 |
|------|------|
| `/splash` | SplashScreen |
| `/login` | LoginScreen |
| `/signup` | SignupScreen |
| `/home` | HomeScreen |
| `/rooms/create` | CreateRoomScreen |
| `/rooms/join` | JoinRoomScreen |
| `/invite/:inviteLinkToken` | InviteScreen |
| `/rooms/:roomId` | RoomDashboardScreen |
| `/rooms/:roomId/members` | MemberStatusScreen |
| `/rooms/:roomId/submit-proof` | SubmitProofScreen |
| `/rooms/:roomId/proofs` | ProofFeedScreen |
| `/notifications` | NotificationScreen |
| `/mypage` | MyPageScreen |

---

## 5. 백엔드 연결 테스트 결과

### 성공한 기능 (전체 완료)
- 회원가입 / 로그인 / 로그아웃
- 보유 포인트 조회 (회원가입 시 100,000 포인트 지급 확인)
- 인증방 생성 후 상세 화면 진입
- 홈에서 내가 참여 중인 방 목록 조회
- 홈에서 방 클릭 → 상세 화면 진입 (TypeError 해결 완료)
- 초대링크/초대코드 복사
- 초대링크로 방 참여 (URL 정규화 처리 완료)
- 인증 제출 (`POST /api/rooms/{roomId}/proofs`, multipart/form-data)
- 인증 피드 조회 (`GET /api/rooms/{roomId}/proofs`, 실제 API 연결 완료)
- 인증 확인 (`POST /api/proofs/{proofId}/confirm`)
- 알림함 목록 조회 (`GET /api/notifications`) 성공
- 알림 클릭 읽음 처리 (`PUT /api/notifications/{id}/read`) 성공
- 모두 읽음 처리 (`PUT /api/notifications/read-all`) 성공
- roomId 기반 알림 → 방 상세 이동 성공
- 홈 화면 알림 unread badge 표시 및 갱신 성공
- Android 에뮬레이터 ROOM_STARTED 알림 수신 후 알림함 확인 성공

### 현재 오류
- 없음 (알려진 TypeError 모두 해결, 에러 메시지 사용자 친화적으로 개선 완료)

---

## 6. 백엔드 API 응답 구조 주의점

백엔드 Room 응답 DTO에서 `id`와 `roomId`가 혼재되어 있다.

| API | 응답 클래스 | id 필드명 |
|-----|-------------|-----------|
| `POST /api/rooms` | `RoomDetailResponse` | `id` |
| `GET /api/rooms` | `RoomSummaryResponse` | `id` |
| `GET /api/rooms/{roomId}` | `RoomDetailEnrichedResponse` | **`roomId`** ← 충돌 |

Flutter 모델에서는 아래처럼 helper를 사용해 둘 다 허용 처리됨:

```dart
id: _readInt(json['roomId'] ?? json['id']),
```

---

## 7. 구현 완료 내역

### room_model.dart (전면 재작성)
- `_readInt`, `_readString`, `_readNullableString`, `_readNullableDate`, `_readBool` helper 추가
- `RoomDetailModel.fromJson`: `json['roomId'] ?? json['id']` 처리, 모든 필드 null-safe
- `RoomMemberModel`: `stakedPoint`, `stakedAt` 필드 추가

### api_client.dart
- `messageFromError(Object error)` 3단계 우선순위로 재구성
  1. `response.data`(`Map` 타입 안전 처리)에서 `message → detail → error` 순서로 추출
  2. `_isUserFriendlyMessage` 필터 통과한 경우만 반환 (100자 초과, HTML, 영문 HTTP status 텍스트, Dio 내부 문자열 차단)
  3. statusCode 기반 한국어 기본 메시지 (`_statusCodeMessage`)
- `_isUserFriendlyMessage(String)`: 개발자용 문자열 필터 private helper
- `_statusCodeMessage(int)`: 400/401/403/404/409/413/500별 한국어 메시지 반환
- connectionError / DioException 아닌 예외 → 짧은 고정 메시지 반환
- 기존 "Spring Boot가 켜져 있는지 확인하세요." 등 개발자용 문구 제거

### ui_mappers.dart
- 앱 전체 UI 텍스트 변환 담당 static 유틸 클래스
- 상태 라벨: `statusLabel`, `memberStatusLabel`, `proofProgressLabel`, `roleLabel`
- 설명 문구: `proofProgressDescription`, `successRuleLabel`, `roomDescriptionFallback`
- 포인트 라벨: `stakePointLabel`, `potPointLabel`, `rewardPointLabel`, `bonusPointLabel`, `feePointLabel`
- 인증 방식: `frequencyTypeLabel`, `frequencyGoalLabel`, `currentPeriodTitle`, `remainingSubmitLabel`, `deadlineLabel`
- const 상수: `confirmNoticeText`, `virtualPointNoticeText`, `penaltyNoticeText`, `bonusNoticeText`, `settlementPolicyTexts`
- 주요 문구 기준
  - `SUCCESS` → `'목표 완료'`
  - `successRuleLabel(n)` → `'전체 인증의 n% 이상을 확인받으면 성공'`
  - `proofProgressDescription(SUCCESS)` → `'목표를 완료했어요.'`

### create_room_screen.dart
- 미션 기간: `durationDays` 상태변수, DAILY [30/60/90/120일] / WEEKLY [28/56/84/112일] 선택 버튼
- `_durationLabel()`: WEEKLY는 "4주 (28일)" 형식 표시
- dateBox: `'미션 시작일' / '방장 시작 다음날'` 표시
- 제출 목표 라벨: DAILY → `'하루 제출 목표'`, WEEKLY → `'주간 제출 목표'`
- 예치금 안내 카드 (`_stakeInfoCard()`): 정산 정책 3줄 + 가상 포인트 안내
- 인증 방식 안내 박스: DAILY/WEEKLY 설명 + 멤버 확인 필요 안내
- 마감 시간 설명: DAILY/WEEKLY 조건부 텍스트

### home_screen.dart
- 앱 설명 카드 (`_appDescriptionCard()`): 포인트 카드 아래 고정 표시
  - 포인트 3개: "예치금으로 책임감 만들기" / "멤버끼리 서로 인증을 확인" / "성공하면 예치금 반환 + 보상"
- 방 카드: `stakePointLabel`, `frequencyTypeLabel`, `frequencyGoalLabel` 사용
- 알림 벨 아이콘 (`_bellIcon()`): 상단 우측, unread count 빨간 배지 (99+까지 표시)
- unread count 갱신: 홈 로드 시 `_refreshUnreadCount()` fire-and-forget, 알림함 복귀 시 `.then()`으로 재갱신
- `_refreshUnreadCount()` 실패 시 기존 값 유지 (홈 로딩에 영향 없음)

### room_dashboard_screen.dart
- 위젯 순서: `_missionSummaryCard` → `_ruleCard` → `_todayStatusCard` → `_myStatusCard` → `_memberPreviewCard` → `_inviteCard`
- `_missionSummaryCard`: 진행 기간, 인증 방식, 성공 기준, 내 예치금, 총 예치금, 인원, 마감 시간 표시
- `_ruleCard`: 5줄 룰 안내 (confirmNoticeText, '확인 완료된 인증만 성공 기준에 반영돼요.', 성공/패널티/보너스)
- `_todayStatusCard` 통계 박스 라벨: `'제출' / '확인' / '남은 제출'` (짧게 고정)
- `_todayStatusCard` 설명 문구: `'확인 완료된 인증만 목표 달성에 반영돼요.'`
- `_myStatusCard`: progressStatus 기반 배지 + `proofProgressDescription` 설명 문구
- `_memberPreviewCard`: `todayStatus['members']` 우선, 없으면 members fallback. `progressStatus ?? expectedResult ?? status` 순서로 상태 읽기. role 표시 포함
- 초대 카드: 초대코드 + 초대링크 각각 복사 버튼
- `_buildInviteLink(String token)` helper: Android(`file://` scheme)에서 `Uri.base.origin` crash 방지, http/https일 때만 origin 사용, 그 외 상대경로(`/invite/$token`) 반환

### join_room_screen.dart
- `_extractInviteToken()`: 전체 URL 붙여넣기 시 토큰만 추출
- 입력 레이블: `'초대 링크 또는 토큰'`, placeholder: `'초대 링크를 붙여넣어 주세요'`
- 미리보기 카드: `frequencyTypeLabel` / `frequencyGoalLabel` / `deadlineLabel` 적용, `Icons.account_balance_wallet_outlined` 사용
- 참여 안내 박스: 예치금 납부 안내 + 멤버 확인 필요 안내 (주황색 카드)

### submit_proof_screen.dart
- 부제목: `'미션 인증을 올려주세요'`
- 안내 문구: 제출만으로 완료 아님, 멤버 확인 필요, 본인 확인 불가 3줄
- 409 특화 처리: `DioException && statusCode == 409` 시 `'미션 기간이 아니거나, 마감 시간이 지났거나, 제출 가능 횟수를 초과했습니다.'` 표시

### proof_feed_screen.dart
- `ConsumerStatefulWidget` 기반, 로딩 / 에러 / 빈 상태 / 리스트 처리
- 헤더 부제목: `'멤버들의 인증을 확인하고 성공을 응원해요'`
- 빈 상태: `'아직 올라온 인증이 없어요.'` + `'첫 번째로 인증을 올려보세요!'`
- 상태 배지: `'확인 완료'` / `'확인 대기'` (공백 포함)
- 파일 URL 처리: 상대경로면 `ApiConstants.baseUrl` 앞에 붙임
- 확인 버튼: `canConfirm` 기반, 클릭 시 silent refresh
- 상태 표시: `isMine` / `alreadyConfirmedByMe` / `canConfirm` / 대기중 분기

### member_status_screen.dart
- 상단 요약 박스: `'목표 달성' / '확인 대기' / '추가 필요'`
- 요약 박스 아래: `'확인 완료된 인증 수를 기준으로 목표 달성을 계산해요.'`
- 멤버 카드 hint 4가지:
  - required==0: `'목표가 아직 설정되지 않았어요'`
  - confirmed>=required: `'목표를 달성했어요'`
  - submitted>=required: `'제출은 충분해요. 멤버 확인을 기다리는 중이에요'`
  - else: `'목표까지 확인 n개 더 필요해요'`
- 진행률 바: `'확인 완료 confirmed/required'` 표시
- 상태 읽기: `progressStatus ?? expectedResult ?? status` 순서
- `_buildSummaryBox` 라벨에 `maxLines: 1, overflow: TextOverflow.ellipsis` 방어 코드

### proof_model.dart
- `ProofSubmitResponseModel.fromJson`: helpers 적용
- `ProofFeedItemModel` 추가 (17개 필드, `proofId ?? id` 처리)

### proof_service.dart
- `getProofFeed(int roomId)`: `GET /api/rooms/{roomId}/proofs`
- `confirmProof(int proofId)`: `POST /api/proofs/{proofId}/confirm`

### 백엔드 (Proof Feed)
- `GET /api/rooms/{roomId}/proofs` 추가 (`ProofController`)
- `ProofFeedItemResponse` DTO 추가
- `ProofRepository.findByRoomOrderByCreatedAtDesc` 추가
- `ProofConfirmationRepository.countByProof` 추가
- `ProofService.getProofFeed` 추가

### notification_model.dart (신규)
- 필드: `id`, `roomId`(nullable), `type`, `title`, `message`, `read`, `readAt`(nullable), `createdAt`
- `fromJson`: 모든 필드 null-safe 처리
- `copyWith`: `read`, `readAt` 낙관적 업데이트용

### notification_service.dart (신규)
- `getNotifications()`: `GET /api/notifications` → `List<NotificationModel>`
- `getUnreadCount()`: `GET /api/notifications/unread-count` → `int`
- `markAsRead(int id)`: `PUT /api/notifications/{id}/read`
- `markAllAsRead()`: `PUT /api/notifications/read-all`

### app_providers.dart (수정)
- `notificationServiceProvider` 추가

### notification_screen.dart (신규)
- `ConsumerStatefulWidget` 기반
- 필터 chip: '전체' / '읽은 알림' 토글
- 낙관적 읽음 처리: 실패 시 rollback + snackbar, 이동 없음
- "모두 읽음": unread 없으면 `onPressed: null` 비활성
- 카드 클릭: 이미 읽음이면 바로 이동, 미읽음이면 API 성공 후 이동
- roomId null이면 읽음 처리만, 이동 없음
- type emoji: ROOM_STARTED🚀 / PROOF_SUBMITTED📷 / PROOF_CONFIRMED✅ / ROOM_SETTLED🏆

---

## 8. 백엔드 연결 기준

Flutter `baseUrl`은 실행 환경별로 다르다.

| 환경 | baseUrl |
|------|---------|
| Flutter Web | `http://localhost:8080` |
| Android Emulator | `http://10.0.2.2:8080` |
| 실제 휴대폰 | `http://PC의 IPv4:8080` |

현재 설정 위치: `lib/core/constants/api_constants.dart`

백엔드 설정:
- CORS 설정 / OPTIONS 허용 완료
- `Authorization: Bearer accessToken` 방식
- 토큰 자동 첨부: `lib/core/network/api_client.dart` Interceptor 처리
- 공개 API (signup / login)는 토큰 첨부 스킵 (`isPublicAuthApi` 분기 추가)

`api_constants.dart` 변경사항:
- `baseUrl`이 `static const String` → `static String get` (플랫폼별 동적 반환)으로 변경
- Web: `http://localhost:8080`, Android 에뮬레이터: `http://10.0.2.2:8080`, 기타: `http://localhost:8080`

`AndroidManifest.xml` 변경사항:
- `<uses-permission android:name="android.permission.INTERNET"/>` 추가
- `android:usesCleartextTraffic="true"` 추가 (HTTP 로컬 개발 서버 접근 허용)

---

## 9. 다음 세션 시작 시 Claude Code가 해야 할 일

1. `docs/FRONTEND_CURRENT_STATE.md` 먼저 읽기
2. `docs/CURRENT_STATE.md` 읽어서 백엔드 현황 파악
3. 코드 수정 전 변경 미리보기 제시
4. 내가 Yes 하기 전까지 적용하지 않기

19단계(NotificationScreen) 완료 — 다음 작업: 20단계 ActivityFeedScreen

---

## 10. 금지

- 백엔드 API를 무작정 바꾸지 말 것
- `id`를 `roomId`로 일괄 변경하는 대규모 수정 금지
- 코드 수정 전 반드시 미리보기 제시

---

## 11. Firebase / FCM 프론트 초기 설정 완료

### 완료 내용
- Firebase CLI 로그인 완료
- FlutterFire CLI 설치 완료
- `flutterfire configure` 실행 → `lib/firebase_options.dart` 자동 생성
- Firebase Android / Web 초기화 성공 확인
- Android 에뮬레이터에서 FCM 토큰 발급 확인
- FCM 권한: `AuthorizationStatus.authorized` 확인

### 추가 패키지 (`pubspec.yaml`)
| 패키지 | 용도 |
|--------|------|
| `firebase_core` | Firebase 앱 초기화 |
| `firebase_messaging` | FCM 토큰 발급 / 푸시 수신 |

### 생성 / 추가 파일
| 파일 | 설명 |
|------|------|
| `lib/firebase_options.dart` | FlutterFire CLI 자동 생성, 플랫폼별 Firebase 설정 |
| `android/app/google-services.json` | Android Firebase 설정 파일 |

### 수정 파일
| 파일 | 변경 내용 |
|------|----------|
| `pubspec.yaml` | `firebase_core`, `firebase_messaging` 의존성 추가 |
| `lib/main.dart` | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` 추가 |
| `android/settings.gradle.kts` | `com.google.gms.google-services:4.4.4` apply false 추가 |
| `android/app/build.gradle.kts` | `com.google.gms.google-services` plugin 적용 |
| `android/app/src/main/AndroidManifest.xml` | `POST_NOTIFICATIONS` 권한 추가 |

### 검증 결과
- Web: `Firebase initialized on Web` 콘솔 로그 확인
- Android 에뮬레이터 FCM TOKEN 발급 확인
- FCM 권한 `AuthorizationStatus.authorized` 확인

---

## 12. 18-4단계 Flutter DeviceToken API 연결 완료

### 구현 위치
- `device_token_service.dart` 미존재 — FCM device token 기능이 `auth_service.dart`에 직접 구현됨

### 로그인 흐름
1. `tokenStorage.saveAccessToken()` — accessToken 먼저 저장 (device-tokens API는 인증 필요)
2. `registerCurrentDeviceTokenSafely()` 호출
   - kIsWeb → 스킵
   - `_currentPlatform()` null (Android/iOS 외) → 스킵
   - `FirebaseMessaging.instance.requestPermission()` 권한 요청
   - `FirebaseMessaging.instance.getToken()` 토큰 발급
   - `POST /api/device-tokens` 호출 (`token`, `platform` 전달)
   - 실패해도 예외 밖으로 던지지 않음 (로그인 차단 방지)

### 로그아웃 흐름
1. `deactivateCurrentDeviceTokenSafely()` — `DELETE /api/device-tokens` 호출 (active=false)
2. `tokenStorage.clearAccessToken()` — 로컬 토큰 삭제
   - FCM 비활성화 실패해도 로그아웃 계속 진행

### 세션 복구 (앱 재진입)
- `auth_controller.dart restoreSession()`: getMe() 성공 후 `registerCurrentDeviceTokenSafely()` 호출
- 앱 재진입 시에도 device token 서버 동기화

### 후속 보강 (미완료)
- `FirebaseMessaging.instance.onTokenRefresh` 핸들러 미구현 → 토큰 갱신 시 자동 재등록 안 됨, 다음 로그인에 반영됨
- `device_token_service.dart` 별도 파일 분리 미완료 — 현재는 `auth_service.dart`에 직접 구현

### 검증 결과
- 로그인 후 device_tokens.active=1 저장 확인
- 로그아웃 후 active=0 확인
- 재로그인 후 active=1 재활성화 확인

---

## 13. 2차 프론트 계획

2차 프론트 기능 후보:

1. ✅ NotificationScreen (19단계 완료)
   - 알림 목록 조회 / 읽음 처리 / 미확인 배지
   - 홈 화면 알림 아이콘 연결
   - roomId 있으면 방 상세 이동

2. ActivityFeedScreen
   - 방 활동 피드 표시
   - 방 참여, 예치, 시작, 인증 제출, 인증 확인, 정산 완료 이벤트

3. FCM foreground/background 처리 및 push 클릭 이동
   - 앱 포그라운드 수신 처리
   - 백그라운드 / 종료 상태 수신 처리
   - 푸시 클릭 시 방 상세 또는 알림함 이동

4. RoomChatScreen
   - WebSocket/STOMP 연결
   - 메시지 실시간 수신
   - 이전 메시지 조회
   - 메시지 전송

5. MissionProgressBoard
   - 현재 파란 요약 카드를 방 전체 대시보드로 확장
   - 전체 진행률, 목표 완료/확인 대기/제출 필요 인원 표시

6. SettlementShareCardScreen
   - 개인/그룹 정산 결과 카드 UI
   - 추후 이미지 저장/공유 확장
