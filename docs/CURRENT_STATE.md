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
- `UserEntity`: `@Getter`, `@Table("users")`
- `UserMeResponse` DTO 추가
- `UserService.signup()`: PointWallet 생성 + SIGNUP_BONUS 연결
- `domain/point/` 패키지: PointWallet, PointLedger, LedgerType, 관련 Repository/Service/Controller/DTO
- `domain/room/` 패키지
  - entity: `Room`, `RoomStatus`, `RoomMember`, `RoomMemberRole`, `RoomMemberStatus`
  - repository: `RoomRepository`, `RoomMemberRepository`
  - service: `RoomService`
  - controller: `RoomController`
  - dto (3단계 완료): `RoomCreateRequest`, `RoomSummaryResponse`, `RoomDetailResponse`
  - dto (4단계 부분 생성): `RoomInviteResponse`, `RoomMemberResponse`, `JoinRoomRequest`

## RoomMemberStatus 값 (전체)
`JOINED, STAKED, SUCCESS, FAILED, SETTLED` — 현재 사용값: `JOINED`

## 문서 상태
research: `00_project_baseline`, `01_point`, `02_room_create`, `03_room_join`
plan: `00_user_me`, `01_point`, `02_room_create`, `03_room_join`

---

## ⚠️ 현재 단계: 4단계 inviteLinkToken/inviteCode 분리 리팩토링 진행 중

**현재 코드는 리팩토링 중간 상태이므로 build가 실패할 수 있다.
다음 세션에서 남은 작업을 완료한 후 build를 실행한다.**

### 배경
기본 join 엔드포인트 구조는 존재하나, **초대 링크 토큰(inviteLinkToken)과 초대 코드(inviteCode)를 분리**하는 설계 변경이 승인되어 리팩토링 중이다.

| 항목 | 역할 |
|------|------|
| `inviteLinkToken` | URL 공유용 긴 토큰 (UUID 32자). 비로그인 미리보기 전용. 민감 정보 없음 |
| `inviteCode` | 참여 검증용 짧은 코드 (6자). 로그인 + body에 포함해야 join 가능. 미리보기 응답에 절대 포함 금지 |

### 이번 세션에서 완료된 변경
- `JoinRoomRequest.java` 신규 생성 (`@NotBlank inviteCode` 1개 필드)
- `Room.java` 에 `inviteLinkToken` 필드 추가 (`@Column(nullable = false, unique = true)`)

### 남은 작업 (다음 세션에서 이어서 구현)

1. **`Room.java`** — `create()` 파라미터에 `String inviteLinkToken` 추가 및 factory 내 대입

2. **`RoomRepository.java`** — 아래 메서드 추가
   ```java
   boolean existsByInviteLinkToken(String inviteLinkToken);
   Optional<Room> findByInviteLinkToken(String inviteLinkToken);
   ```

3. **`RoomService.java`** — 4곳 수정
   - `createRoom()`: inviteCode(6자) + inviteLinkToken(32자) 모두 생성, `Room.create()` 호출에 전달
   - `generateInviteLinkToken()` private 메서드 추가 (중복 체크 포함)
   - `getRoomByInviteCode()` → `getRoomByInviteLinkToken(String)` 이름·내부 조회 변경
   - `joinRoom()`: `JoinRoomRequest request` 파라미터 추가, inviteCode 불일치 → 400

4. **`RoomController.java`** — 2곳 수정
   - `GET /api/rooms/invite/{inviteLinkToken}`: path variable 이름 변경, service 메서드명 변경
   - `POST /api/rooms/{roomId}/join`: `@Valid @RequestBody JoinRoomRequest request` 추가

5. **`RoomSummaryResponse.java` / `RoomDetailResponse.java`** — `inviteLinkToken` 필드 추가 (inviteCode 유지)

6. **SecurityConfig** — `GET /api/rooms/invite/**` permitAll 1줄 추가 (사용자가 직접 처리 예정)

### 유저 지정 필수 조건
- SecurityConfig 절대 수정 금지 (사용자 직접 처리)
- RoomInviteResponse에 inviteCode 포함 금지
- joinRoom: request.getInviteCode() vs room.getInviteCode() 불일치 → 400
- 방 참여 이후 inviteCode 재요구 금지

---

## 다음 세션 시작 프롬프트
```
CLAUDE.md와 docs/CURRENT_STATE.md를 읽어.
4단계 inviteLinkToken/inviteCode 분리 리팩토링을 이어서 구현한다.
CURRENT_STATE.md의 "남은 작업" 목록 순서대로 진행해.
research/plan은 이미 있으므로 새로 작성하지 않아도 된다.
SecurityConfig는 절대 수정하지 마. RoomInviteResponse에 inviteCode 포함 금지.
먼저 현재 코드 상태를 확인한 뒤, 남은 작업 목록과 일치하면 구현을 진행해.
```
