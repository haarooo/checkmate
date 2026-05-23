# 18_1_device_token_research.md

## 1. 기능 목표

Flutter에서 발급받은 FCM token을 백엔드 DB에 저장한다.
이후 FCM 발송 단계(18-2, 18-3)에서 사용자의 활성 token을 조회할 수 있는 기반을 만든다.
이번 단계는 FCM 발송 구현이 아니라 DeviceToken 저장 구조에 집중한다.

## 2. FCM token이란

Firebase가 앱 설치/실행 환경(기기+앱 인스턴스)별로 발급하는 고유 식별자다.
서버는 이 token을 알아야 특정 기기에 push를 보낼 수 있다.
token은 앱 재설치, 데이터 삭제, Firebase 내부 갱신에 의해 교체될 수 있다.
따라서 앱은 token 발급·갱신 시마다 백엔드에 재등록해야 한다.

## 3. Notification과 DeviceToken의 차이

| 항목 | Notification | DeviceToken |
|---|---|---|
| 역할 | 앱 내 알림함 원본 데이터 | push 발송용 기기 주소 |
| 저장 시점 | 이벤트 발생 시 | 로그인·token 갱신 시 |
| 발송과의 관계 | 내용(title/message) 저장 | 수신 대상 주소 저장 |

Notification DB 저장이 먼저고, FCM은 그 내용을 기기로 전달하는 수단이다.

## 4. 왜 DeviceToken DB가 필요한가

- 한 사용자가 여러 기기를 사용할 수 있다 → 기기별 token 저장 필요.
- 한 기기에서 계정을 전환할 수 있다 → 최신 로그인 사용자로 매핑 필요.
- 로그아웃한 기기에는 push를 보내면 안 된다 → active 상태 관리 필요.
- FCM 발송 시 active=true token만 조회해 불필요한 발송을 막는다.

## 5. Entity 설계 후보

DevicePlatform enum: ANDROID, IOS, WEB
(플랫폼별로 FCM 페이로드 구조가 다를 수 있어 저장한다.)

DeviceToken 필드:
- id, user(ManyToOne LAZY NOT NULL), token(UNIQUE), platform, active(boolean), BaseTime 상속
- DB 설계(02_DB_DESIGN.md)와 일치: device_tokens.token UNIQUE 명시

## 6. token 중복 정책

같은 token이 이미 DB에 존재할 때 처리 비교:

| 방식 | 동작 | 평가 |
|---|---|---|
| 409 처리 | 중복이면 에러 반환 | 계정 전환 시 등록 실패. MVP에 부적합 |
| 재할당 | 현재 로그인 사용자로 user 교체 + active=true | 기기 기준 매핑. 단순하고 안전 |

추천: **재할당**
이유: FCM token은 기기+앱 인스턴스 기준으로 발급된다.
동일 기기에서 계정이 바뀌면 가장 최근 로그인 사용자가 push를 받아야 한다.
이전 소유자가 로그아웃 시 deactivate를 호출하지 못했더라도, token row의 user를 현재 로그인 사용자로 재할당하면 이후 발송 대상은 최신 사용자 기준으로 정리된다.

세부 분기:
- 같은 token + 같은 user → platform 갱신 + active=true (재활성화)
- 같은 token + 다른 user → user 교체 + platform 갱신 + active=true (재할당)

## 7. 삭제 대신 active=false 정책

실제 row 삭제보다 active=false가 유리한 이유:
- 재로그인 시 동일 token을 active=true로 복구 가능 (INSERT 없이 UPDATE).
- 발송 실패 추적 및 디버깅에 이력이 남는다.
- DB UNIQUE 제약을 유지하면서 상태만 전환한다.

## 8. API 설계 후보

POST /api/device-tokens — token 등록/갱신, 로그인 필요

DELETE token 전달 방식 비교:

| 방식 | 예시 | 장점 | 단점 |
|---|---|---|---|
| path variable | DELETE /api/device-tokens/{token} | RESTful, API 스펙 일치 | FCM token에 `:` 포함 시 URL 인코딩 필요, 긴 문자열 URL 가독성 저하 |
| query param | DELETE /api/device-tokens?token=... | 인코딩 자동처리, 가독성 | REST 관례와 다소 거리있음 |
| request body | DELETE /api/device-tokens (body) | 인코딩 문제 없음, 길이 제한 없음 | HTTP DELETE에 body는 비표준 관행 (Spring은 지원) |

FCM token 특성:
- 152자 이상, `:`(콜론) 포함 가능. URL path에서 `%3A`로 인코딩 필요.
- `/`(슬래시)는 포함되지 않아 path variable 파싱 오류는 없다.
- Dio(Flutter)에서도 URL을 직접 문자열로 조립하면 인코딩 실수가 날 수 있다. 따라서 긴 FCM token은 path variable보다 request body로 전달하는 편이 안전하다.

추천 후보: **request body**
이유: 길이·특수문자 제약 없음. Flutter → Spring 전송 시 인코딩 실수 위험 제거.
단, 03_API_SPEC.md에 `DELETE /api/device-tokens/{token}` (path variable)로 명시돼 있어
plan에서 최종 방식을 확정한다.

## 9. Repository 후보

- `findByToken(String token)` — 등록 시 중복 여부 확인
- `findAllByUserAndActiveTrue(UserEntity user)` — FCM 발송 시 활성 기기 조회 (18-2 예정)
- `findByUserAndToken(UserEntity user, String token)` — 비활성화 시 소유자 확인

## 10. Service 후보

- `register(email, request)` — 등록/재활성화/재할당
- `deactivate(email, token)` — active=false 처리
- `findActiveTokens(UserEntity user)` — 18-2 FCM 발송 단계에서 사용 예정

## 11. 이번 단계 제외 범위

- Firebase Admin SDK 추가
- FCM 실제 발송 구현
- NotificationService와 FCM 연결
- Flutter 자동 token 등록 코드
- WebSocket / 채팅

## 12. 위험과 대응

| 위험 | 대응 |
|---|---|
| 같은 token 중복 저장 | DB UNIQUE 제약 + 서비스 레이어 재할당 로직 |
| 로그아웃 기기에 push 발송 | active=false 후 findAllByUserAndActiveTrue로 조회 |
| 타인 token 비활성화 | deactivate에서 user 일치 검사 → 403 |
| token 문자열 URL 전달 오류 | plan에서 전달 방식 확정 |
| FCM 발송과 혼재 | 18-1은 저장 API만, 발송은 18-2에서 분리 구현 |

## 13. 테스트 전략

1. POST /api/device-tokens — 신규 token 등록 201 확인
2. 같은 token 재등록 (같은 user) — 200, active=true, platform 갱신 확인
3. 같은 token 다른 user로 재등록 — 200, user 재할당 확인
4. DELETE — active=false 전환 확인
5. 타인 token 비활성화 → 403 확인
6. 없는 token 비활성화 → 404 확인
7. blank token POST → 400 확인
8. 유효하지 않은 platform → 400 확인

## 14. 추천 결론

| 항목 | 후보 |
|---|---|
| 패키지 | domain/device/ |
| Entity 필드 | id, user, token(UNIQUE), platform, active, BaseTime |
| token 중복 정책 | 재할당 (같은 user: reactivate, 다른 user: reassign) |
| 비활성화 방식 | active=false (row 유지) |
| API | POST /api/device-tokens, DELETE 방식 미확정 |
| DELETE 전달 방식 | plan에서 확정 (request body 추천, API 스펙은 path variable) |

plan에서 확정할 사항:
- DELETE token 전달 방식 (path variable vs request body)
- findByUserAndToken 포함 여부
- DeviceTokenResponse 응답 필드 범위
