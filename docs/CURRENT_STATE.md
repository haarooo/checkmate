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
- `POST /api/rooms` 방 생성 (RECRUITING, inviteCode 6자 + inviteLinkToken 32자 자동 생성, 생성자 OWNER 등록)
  - proofFrequencyType (DAILY / WEEKLY), requiredProofCount 필수 입력
  - WEEKLY: durationDays가 7의 배수 아니면 400, requiredProofCount > 7이면 400
  - DAILY: requiredProofCount 1 이상이면 허용
  - RoomInviteResponse / RoomSummaryResponse / RoomDetailResponse에 두 필드 포함
- SecurityConfig: `/error` permitAll 추가 (ResponseStatusException error dispatch 403 방지)
- `GET /api/rooms` 내가 속한 방 목록 조회
- `GET /api/rooms/{roomId}` 방 상세 조회 (비멤버 403, 없는 방 404)
- `GET /api/rooms/invite/{inviteLinkToken}` 초대 링크 미리보기 (비로그인 허용, inviteCode 미포함)
- `POST /api/rooms/{roomId}/join` 방 참여 (inviteCode body 검증, 불일치 400, 중복/만원/모집중아님 409)
- `GET /api/rooms/{roomId}/members` 방 멤버 목록 조회 (비멤버 403)
- `POST /api/rooms/{roomId}/stake` 예치금 납부 (잔액부족 400, 비멤버 403, 상태충돌 409, 전원 STAKED 시 READY 자동 전환)
- `POST /api/rooms/{roomId}/start` 방 시작 (OWNER만, READY 상태만, 인원/STAKED 이중 검증,
  IN_PROGRESS 전환, missionStartDate=Asia/Seoul 기준 오늘+1일, missionEndDate=start+durationDays-1일)
- Local File Upload 인프라 구성 (API 없음, 8단계 Proof Submit에서 실제 사용)
  - 허용: 이미지(jpg/jpeg/png/gif/webp) + 동영상(mp4/mov/webm)
  - 저장 위치: 프로젝트 루트 uploads/proofs/, storedName=UUID+확장자
  - GET /uploads/** 정적 파일 서빙 (WebConfig), SecurityConfig permitAll 사용자 직접 추가
  - .gitignore에 uploads/ 추가

주의:
- 위 기능을 처음부터 다시 만들지 않는다.
- SecurityConfig/JWT/User/Point/Room 구조는 먼저 읽고 기존 패턴을 따른다.
- 대규모 수정 필요 시 구현하지 말고 보고한다.

## 완료된 코드 정리
- `UserEntity`: `@Getter`, `@Table("users")`
- `UserMeResponse` DTO 추가
- `UserService.signup()`: PointWallet 생성 + SIGNUP_BONUS 연결
- `domain/point/` 패키지: PointWallet, PointLedger, LedgerType, 관련 Repository/Service/Controller/DTO
- `global/storage/` 패키지: `LocalFileStorageService`, `FileUploadResult`
- `global/config/` 패키지: `WebConfig` (/uploads/** 정적 파일 서빙)
- `domain/room/` 패키지
  - entity: `Room` (start() 추가), `RoomStatus`, `RoomMember`, `RoomMemberRole`, `RoomMemberStatus`
  - repository: `RoomRepository`, `RoomMemberRepository`
  - service: `RoomService`
  - controller: `RoomController`
  - dto: `RoomCreateRequest`, `RoomSummaryResponse`, `RoomDetailResponse`, `RoomInviteResponse`, `RoomMemberResponse`, `JoinRoomRequest`

## inviteLinkToken / inviteCode 설계 확정

| 항목 | 값 | 역할 |
|------|-----|------|
| `inviteCode` | 6자 (UUID 앞 6자리) | 방 참여 검증용. POST /join body로 전달. 불일치 시 400 |
| `inviteLinkToken` | 32자 (UUID 하이픈 제거) | 초대 링크 URL 토큰. 비로그인 미리보기 전용 |

- 프론트 링크 형식: `{frontendDomain}/invite/{inviteLinkToken}`
- DB에는 token만 저장 (전체 URL 저장 안 함)
- `RoomInviteResponse`에 inviteCode·inviteLinkToken 모두 포함 금지
- `RoomSummaryResponse`, `RoomDetailResponse`에는 둘 다 포함 (멤버용)

## RoomMemberStatus 값 (전체)
`JOINED, STAKED, SUCCESS, FAILED, SETTLED` — 현재 사용값: `JOINED`, `STAKED`

## Proof 제출 기준 확정
- DAILY: 같은 room+user+proofDate 당일 제출 수 < requiredProofCount → 제출 가능, 초과 409
- WEEKLY: Asia/Seoul 월~일 주차 내 같은 room+user 제출 수 < requiredProofCount → 제출 가능, 초과 409
- content 또는 file 중 하나 필수, file = 이미지(jpg/jpeg/png/gif/webp) or 동영상(mp4/mov/webm)

## 5단계 stake 테스트 완료 내용
- 정상 stake 성공
- PointWallet balance 차감 확인
- PointLedger ROOM_STAKE 음수 이력 + roomId 확인
- RoomMember status STAKED 전환 확인
- Room potPoint 증가 확인
- 전원 예치 완료 시 Room status READY 자동 전환 확인

## 5단계-b proofFrequencyType 테스트 완료 내용
- build 성공
- DAILY + requiredProofCount=1 방 생성 201 확인
- WEEKLY + durationDays=7 + requiredProofCount=3 방 생성 201 확인
- WEEKLY + durationDays=5 → 400 확인
- WEEKLY + requiredProofCount=8 → 400 확인
- POST /api/rooms 응답에 proofFrequencyType, requiredProofCount 포함 확인
- GET /api/rooms, GET /api/rooms/{roomId}, GET /api/rooms/invite/{token} 동일 필드 포함 확인

## 7단계 Local File Upload 완료 내용
- build 성공, 서버 실행 정상
- LocalFileStorageService.store() 구현 (검증 → 저장 → FileUploadResult 반환)
- WebConfig /uploads/** 정적 서빙 구성
- SecurityConfig GET /uploads/** permitAll 사용자 직접 추가 완료
- 실제 업로드 테스트는 8단계 Proof Submit에서 진행

## 6단계 start 테스트 완료 내용
- 정상 start 200 확인 (OWNER, READY 상태)
- 응답 status IN_PROGRESS 확인
- missionStartDate = 오늘+1일, missionEndDate = start+durationDays-1일 확인
- 비OWNER(MEMBER) start → 403 확인
- RECRUITING 상태 방 start → 409 확인
- IN_PROGRESS 방 중복 start → 409 확인
- 비멤버 start → 403 확인

## 다음 단계
- 8단계: Proof Submit (content/file 중 하나 필수, DAILY/WEEKLY 기준별 requiredProofCount 제출 제한, SUBMITTED)

## 문서 상태
research: `00_project_baseline`, `01_point`, `02_room_create`, `03_room_join`, `04_room_stake`, `05_room_proof_frequency`, `06_room_start`, `07_local_file_upload`
plan: `00_user_me`, `01_point`, `02_room_create`, `03_room_join`, `04_room_stake`, `05_room_proof_frequency`, `06_room_start`, `07_local_file_upload`
