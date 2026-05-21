# FRONTEND_CURRENT_STATE.md

마지막 업데이트: 2026-05-21

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

### 현재 오류
- 없음 (알려진 TypeError 모두 해결)

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

### room_dashboard_screen.dart
- 초대 카드: 초대코드 + 초대링크 각각 복사 버튼
- RECRUITING/READY 상태 안내 문구: "미션 시작 후 인증 제출이 가능합니다."
- 초대링크 URL 형식: `'${Uri.base.origin}/#/invite/$token'` (hash routing)

### join_room_screen.dart
- `_extractInviteToken()` 추가: 전체 URL 붙여넣기 시 토큰만 추출
- `initState` / `loadPreview` 에서 정규화 적용

### proof_model.dart (전면 재작성)
- `ProofSubmitResponseModel.fromJson`: helpers 적용
- `ProofFeedItemModel` 추가 (17개 필드, `proofId ?? id` 처리)
- helper 함수 추가 (room_model.dart와 동일 패턴)

### proof_service.dart
- `getProofFeed(int roomId)`: `GET /api/rooms/{roomId}/proofs` 호출
- `confirmProof(int proofId)`: `POST /api/proofs/{proofId}/confirm` (기존)

### proof_feed_screen.dart (전면 재작성)
- `ConsumerStatefulWidget` 기반
- 로딩 / 에러 / 빈 상태 / 리스트 상태 처리
- `RefreshIndicator` 지원
- 이미지: `Image.network()`, 동영상: 재생 아이콘
- 파일 URL 처리: 상대경로면 `ApiConstants.baseUrl` 앞에 붙임
- 확인 버튼: `canConfirm` 기반, 클릭 시 silent refresh
- 상태 표시: `isMine` / `alreadyConfirmedByMe` / `canConfirm` / 대기중 분기

### 백엔드 (Proof Feed)
- `GET /api/rooms/{roomId}/proofs` 추가 (`ProofController`)
- `ProofFeedItemResponse` DTO 추가
- `ProofRepository.findByRoomOrderByCreatedAtDesc` 추가
- `ProofConfirmationRepository.countByProof` 추가
- `ProofService.getProofFeed` 추가

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

---

## 9. 다음 세션 시작 시 Claude Code가 해야 할 일

1. `docs/FRONTEND_CURRENT_STATE.md` 먼저 읽기
2. `docs/CURRENT_STATE.md` 읽어서 백엔드 현황 파악
3. 코드 수정 전 변경 미리보기 제시
4. 내가 Yes 하기 전까지 적용하지 않기

---

## 10. 금지

- 백엔드 API를 무작정 바꾸지 말 것
- `id`를 `roomId`로 일괄 변경하는 대규모 수정 금지
- 코드 수정 전 반드시 미리보기 제시
