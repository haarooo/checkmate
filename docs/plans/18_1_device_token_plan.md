# 18_1_device_token_plan.md

## 1. 구현 목표

- Flutter에서 발급받은 FCM token을 백엔드 DB에 저장한다.
- 로그인 사용자가 자신의 token을 등록/갱신할 수 있게 한다.
- 로그아웃 시 token을 삭제하지 않고 active=false로 비활성화한다.
- 다음 FCM 발송 단계에서 active=true token을 조회할 수 있게 한다.

## 2. 이번 단계 구현 범위

포함:
- DevicePlatform enum
- DeviceToken Entity
- DeviceTokenRepository
- DeviceTokenRegisterRequest
- DeviceTokenDeactivateRequest
- DeviceTokenResponse
- DeviceTokenService
- DeviceTokenController
- POST /api/device-tokens
- DELETE /api/device-tokens

제외:
- Firebase Admin SDK
- FCM 실제 발송
- NotificationService 수정
- Flutter 자동 token 등록 코드
- WebSocket / 채팅

## 3. 패키지 구조

```
src/main/java/com/example/checkmate/domain/device/
├── entity/DevicePlatform.java
├── entity/DeviceToken.java
├── repository/DeviceTokenRepository.java
├── dto/DeviceTokenRegisterRequest.java
├── dto/DeviceTokenDeactivateRequest.java
├── dto/DeviceTokenResponse.java
├── service/DeviceTokenService.java
└── controller/DeviceTokenController.java
```

## 4. Entity 설계

DevicePlatform: ANDROID, IOS, WEB

DeviceToken:
- id
- user: UserEntity ManyToOne LAZY NOT NULL
- token: String UNIQUE length=512
- platform: DevicePlatform @Enumerated(STRING)
- active: boolean NOT NULL
- BaseTime 상속 (createdAt, updatedAt)

정책:
- token UNIQUE: 같은 기기 주소가 두 row로 저장되면 FCM 중복 발송이 발생한다.
- active=false: 로그아웃 기기를 발송 대상에서 제외하면서 이력을 보존한다.
- 재등록 시 기존 row 갱신: 새 INSERT 없이 UPDATE로 처리해 UNIQUE 충돌을 피한다.
- 다른 사용자 token 재할당: 기기 전환 시 최신 로그인 사용자에게 매핑한다.

## 5. API 설계

### POST /api/device-tokens

요청: { token, platform }
응답: DeviceTokenResponse
상태코드: 200 OK 단일 사용
- 신규/갱신/재할당 모두 200으로 통일한다.
- 이유: 이 API는 upsert 성격이므로 201/200 구분이 클라이언트에게 불필요하다.

### DELETE /api/device-tokens

요청: request body { token }
응답: 204 No Content

DELETE token 전달 방식 확정: **request body**
- FCM token은 152자 이상이며 `:`(콜론) 포함 가능.
- path variable은 URL 인코딩 실수 위험이 있다.
- 03_API_SPEC.md는 path variable로 명시되어 있으나, 안전성을 위해 request body로 변경한다.

정책:
- 본인 token만 비활성화 가능. 타인 token → 403.
- 없는 token → 404.

## 6. DTO 설계

DeviceTokenRegisterRequest: String token, String platform
DeviceTokenDeactivateRequest: String token
DeviceTokenResponse: Long id, String token, String platform,
                     boolean active, LocalDateTime createdAt, LocalDateTime updatedAt

## 7. Repository 설계

| 메서드 | 용도 |
|---|---|
| findByToken(String token) | 등록 시 중복 확인 및 재할당 판단 |
| findByUserAndToken(UserEntity user, String token) | 비활성화 시 소유자 확인에 활용 가능 |
| findAllByUserAndActiveTrue(UserEntity user) | 18-2 FCM 발송 시 수신 기기 조회 예정 |

## 8. Entity 메서드 설계

- create(user, token, platform): 신규 저장
- reactivate(platform): 같은 user 재등록 — active=true, platform 갱신
- reassign(user, platform): 다른 user 재등록 — user 교체, active=true, platform 갱신
- deactivate(): active=false

## 9. Service 설계

register(email, request) 흐름:
1. token blank → 400
2. platform blank → 400
3. platform enum 변환 실패 → 400
4. email → UserEntity 조회 (없으면 404)
5. findByToken(token)
6. 없음 → create + save
7. 있음, 같은 user → reactivate
8. 있음, 다른 user → reassign
9. DeviceTokenResponse 반환

deactivate(email, request) 흐름:
1. token blank → 400
2. email → UserEntity 조회 (없으면 404)
3. findByToken(token) → 없으면 404
4. 소유자 불일치 → 403
5. deactivate()
6. 204 반환

findActiveTokens(user):
- 18-2 FCM 발송 단계에서 호출 예정. 이번 단계는 Controller 노출 없음.

## 10. 예외 정책

| 조건 | 상태 |
|---|---|
| token blank | 400 |
| platform blank | 400 |
| invalid platform | 400 |
| user 없음 | 404 |
| token 없음 (비활성화 시) | 404 |
| 타인 token 비활성화 | 403 |

## 11. 주석 작성 기준

새 코드에 의미 있는 주석을 단다. 대상:
- FCM token이 왜 필요한지
- token UNIQUE가 왜 필요한지
- active=false 방식을 선택한 이유
- 다른 사용자 token 재할당 이유
- findActiveTokens가 다음 단계에서 쓰이는 이유
- Controller API가 프론트에서 언제 호출되는지

금지: getter 수준 주석, 모든 줄 주석, 기존 코드 주석 추가

## 12. 구현 순서

1. DevicePlatform 생성
2. DeviceToken 생성
3. DeviceTokenRepository 생성
4. DeviceTokenRegisterRequest 생성
5. DeviceTokenDeactivateRequest 생성
6. DeviceTokenResponse 생성
7. DeviceTokenService 생성
8. DeviceTokenController 생성
9. ./gradlew.bat clean build
10. API 테스트
11. CURRENT_STATE.md 갱신

## 13. 테스트 방법

1. POST /api/device-tokens — 신규 token 등록 200 확인
2. 같은 token 재등록 (같은 user) — 중복 row 없이 갱신 200 확인
3. DELETE /api/device-tokens — active=false 확인, 204 확인
4. 비활성화 후 재등록 — active=true 복구 확인
5. 다른 사용자로 같은 token 등록 — user 재할당 200 확인
6. 타인 token 비활성화 → 403 확인
7. 없는 token 비활성화 → 404 확인
8. blank token → 400 확인
9. invalid platform → 400 확인

빌드: ./gradlew.bat clean build

## 14. 주의사항

- Firebase Admin SDK 구현 금지
- FCM 발송 구현 금지
- NotificationService 수정 금지
- Flutter 코드 수정 금지
- 기존 MVP 기능 수정 금지
- 이번 단계는 DeviceToken 저장/비활성화 API까지만 구현
