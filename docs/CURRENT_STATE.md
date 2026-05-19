# CURRENT_STATE.md

현재 진행 상태만 기록한다. 정책은 `01_BUSINESS_RULES.md`.

## 완료된 기반
- 회원가입 (가입 시 PointWallet 생성 + SIGNUP_BONUS 100,000P 자동 지급 포함)
- 로그인
- JWT 인증 / JWT 필터 / Spring Security 설정 / Swagger/OpenAPI 설정
- `GET /api/users/me` JSON 응답
- `GET /api/points/me` 잔액 조회
- `GET /api/points/me/ledgers` 이력 조회 (최신순)
- `POST /api/points/test/charge` 테스트 충전
- `POST /api/rooms` 방 생성 (RECRUITING, inviteCode 자동생성, 생성자 OWNER 등록)
- `GET /api/rooms` 내가 속한 방 목록 조회
- `GET /api/rooms/{roomId}` 방 상세 조회 (비멤버 403, 없는 방 404)

주의:
- 위 기능을 처음부터 다시 만들지 않는다.
- SecurityConfig/JWT/User/Point/Room 구조는 먼저 읽고 기존 패턴을 따른다.
- 대규모 수정 필요 시 구현하지 말고 보고한다.

## 완료된 코드 정리
- `UserEntity`: `@Data` → `@Getter`, `@Table("users")`
- `UserMeResponse` DTO 추가
- `UserService.signup()`: PointWallet 생성 + SIGNUP_BONUS 연결
- `domain/point/` 패키지: PointWallet, PointLedger, LedgerType, 관련 Repository/Service/Controller/DTO
- `domain/room/` 패키지 신규 생성
  - entity: `Room`, `RoomStatus`, `RoomMember`, `RoomMemberRole`, `RoomMemberStatus`
  - repository: `RoomRepository`, `RoomMemberRepository`
  - service: `RoomService`
  - controller: `RoomController`
  - dto: `RoomCreateRequest`, `RoomSummaryResponse`, `RoomDetailResponse`

## RoomMemberStatus 값 (전체)
`JOINED, STAKED, SUCCESS, FAILED, SETTLED` — 현재 사용값: `JOINED`

## 문서 상태
research: `00_project_baseline`, `01_point`, `02_room_create`
plan: `00_user_me`, `01_point`, `02_room_create`

## 현재 단계
`04_IMPLEMENTATION_ORDER.md` 3단계 완료.
4단계(RoomMember / Join) 시작 전.

## 다음 작업
`04_IMPLEMENTATION_ORDER.md` 4단계: RoomMember / Join.
- `GET /api/rooms/invite/{inviteCode}` 초대 코드로 방 조회
- `POST /api/rooms/{roomId}/join` 방 참여 (중복/인원 초과 방지)

## 시작 프롬프트
CLAUDE.md, CURRENT_STATE, BUSINESS_RULES를 읽어. 이번 작업은 RoomMember Join 구현이다. 아직 구현하지 마. 관련 코드와 DB 설계를 분석한 뒤 research와 plan을 작성해. 내가 승인하기 전까지 코드 수정 금지.
