# CURRENT_STATE.md

현재 진행 상태만 기록한다. 정책은 `01_BUSINESS_RULES.md`.

## 완료된 기반
- 회원가입 (가입 시 PointWallet 생성 + SIGNUP_BONUS 100,000P 자동 지급 포함)
- 로그인
- JWT 인증
- JWT 필터
- Spring Security 설정
- Swagger/OpenAPI 설정
- 기본 User 도메인
- `GET /api/users/me` JSON 응답 (id, email, name, nickname, role)
- `GET /api/points/me` 포인트 잔액 조회
- `GET /api/points/me/ledgers` 포인트 이력 조회 (최신순)
- `POST /api/points/test/charge` 테스트 충전

주의:
- 위 기능을 처음부터 다시 만들지 않는다.
- SecurityConfig/JWT/User/Point 구조는 먼저 읽고 기존 패턴을 따른다.
- 대규모 수정 필요 시 구현하지 말고 보고한다.

## 완료된 코드 정리
- `UserEntity`: `@Data` → `@Getter`, `@Table("user")` → `@Table("users")`
- `UserRepository`: 미사용 import 제거
- `JwtTokenProvider`: 중복 `@Component` import 제거
- `UserMeResponse` DTO 추가 (domain/user/dto)
- `UserService.signup()`: 가입 완료 후 `pointService.createInitialWallet(user)` 호출 추가
- `domain/point/` 패키지 신규 생성
  - entity: `PointWallet`, `PointLedger`, `LedgerType`
  - repository: `PointWalletRepository`, `PointLedgerRepository`
  - service: `PointService`
  - controller: `PointController`
  - dto: `PointWalletResponse`, `PointLedgerResponse`, `TestChargeRequest`

## 문서 상태
CLAUDE.md와 docs 문서 정리 완료.
research: `docs/research/00_project_baseline_research.md`, `docs/research/01_point_research.md`
plan: `docs/plans/00_user_me_plan.md`, `docs/plans/01_point_plan.md`

## 현재 단계
`04_IMPLEMENTATION_ORDER.md` 2단계 완료.
3단계(Room 생성) 시작 전.

## 다음 작업
`04_IMPLEMENTATION_ORDER.md` 3단계: Room 생성.
- `POST /api/rooms` — RECRUITING 상태, inviteCode 자동 생성, 생성자 OWNER로 RoomMember 등록
- proofType 필드 금지, is_public 필드 금지

## 시작 프롬프트
CLAUDE.md, CURRENT_STATE, BUSINESS_RULES를 읽어. 이번 작업은 Room 생성 도메인 구현이다. 아직 구현하지 마. 관련 코드와 DB 설계를 분석한 뒤 research와 plan을 작성해. 내가 승인하기 전까지 코드 수정 금지.
