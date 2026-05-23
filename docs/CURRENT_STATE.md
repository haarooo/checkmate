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
  - durationDays < 28 → 400 (DAILY/WEEKLY 공통)
  - WEEKLY: durationDays가 7의 배수 아니면 400, requiredProofCount > 7이면 400
  - DAILY: requiredProofCount 1 이상이면 허용
  - stakePoint < 1,000 or > 50,000 → 400
  - RoomInviteResponse / RoomSummaryResponse / RoomDetailResponse에 두 필드 포함
- SecurityConfig: `/error` permitAll 추가 (ResponseStatusException error dispatch 403 방지)
- `GET /api/rooms` 내가 속한 방 목록 조회
- `GET /api/rooms/{roomId}` 방 상세 조회 (비멤버 403, 없는 방 404)
  - 응답: roomId, title, description, status, inviteCode, inviteLinkToken
  - ownerId, ownerNickname, myRole, myMemberStatus, createdAt 포함
  - members 목록 (userId, nickname, role, status, stakedPoint, joinedAt, stakedAt) 포함
- `GET /api/rooms/invite/{inviteLinkToken}` 초대 링크 미리보기 (비로그인 허용, inviteCode 미포함)
- `POST /api/rooms/{roomId}/join` 방 참여 (inviteCode body 검증, 불일치 400, 중복/만원/모집중아님 409)
- `GET /api/rooms/{roomId}/members` 방 멤버 목록 조회 (비멤버 403)
  - 응답에 stakedPoint, stakedAt 포함
- `GET /api/rooms/{roomId}/settlement` 정산 결과 조회 (비멤버 403, 정산 전 409)
- `POST /api/rooms/{roomId}/stake` 예치금 납부 (잔액부족 400, 비멤버 403, 상태충돌 409, 전원 STAKED 시 READY 자동 전환)
- `POST /api/rooms/{roomId}/start` 방 시작 (OWNER만, READY 상태만, 인원/STAKED 이중 검증,
  IN_PROGRESS 전환, missionStartDate=Asia/Seoul 기준 오늘+1일, missionEndDate=start+durationDays-1일)
- `POST /api/rooms/{roomId}/proofs` 인증 제출 (multipart/form-data, content/file 중 하나 필수,
  IN_PROGRESS + 미션 기간 내에만 허용, DAILY/WEEKLY 기준 requiredProofCount 제출 수 제한, 초과 409, SUBMITTED)
  - proofDate < missionStartDate → 409 (start 당일 제출 차단)
  - 파일 있으면 LocalFileStorageService.store() → uploads/proofs/ 저장
  - deadlineTime 이후 제출 → 409 (Asia/Seoul 기준 nowTime.isAfter(room.deadlineTime), 정각은 허용)
- `POST /api/proofs/{proofId}/confirm` 인증 확인 (방 멤버만, 본인 확인 금지 403, 중복 확인 409,
  CONFIRMED 전환, confirmedAt 최초 확인 시점 고정, 이미 CONFIRMED면 200 idempotent)
- `GET /api/rooms/{roomId}/proofs` 인증 피드 조회 (방 멤버만, 비멤버 403, 방 없으면 404)
  - createdAt DESC 정렬
  - 응답: proofId, roomId, userId, nickname, content, fileUrl, fileOriginalName, fileContentType,
    status, proofDate, createdAt, confirmedAt, confirmationCount, requiredConfirmationCount(1),
    canConfirm, isMine, alreadyConfirmedByMe
  - canConfirm = !isMine && !alreadyConfirmedByMe
- `GET /api/rooms/{roomId}/today-status` 현재 기간 인증 현황 조회
  - IN_PROGRESS + 미션 기간 내에만 허용, 비멤버 403, 기간 외 409
  - DAILY: 오늘 기준 / WEEKLY: 이번 주 월~일 기준
  - 멤버별 submittedCount, confirmedCount, status(SUCCESS/WAITING_CONFIRM/NEED_SUBMIT/MISSED)
  - deadlinePassed: DAILY는 매일, WEEKLY는 일요일 deadlineTime 이후
  - myStatus + members 포함
- `POST /api/rooms/{roomId}/settle` 방 정산 (방 멤버 누구나, 비멤버 403, findByIdForUpdate 비관적 락)
  - room.status != IN_PROGRESS → 409, today <= missionEndDate → 409, 이미 Settlement 존재 → 409
  - CONFIRMED만 성공 인증으로 계산, requiredSuccessCount 비교로 SUCCESS/FAILED 판정
  - 전원 성공: stakePoint 반환(REFUND) + successBonusPoint = min(stakePoint*10/100, 5000)(SUCCESS_BONUS)
  - 일부 성공: 성공자 stakePoint 반환(REFUND) + failedPot 균등 분배(REWARD), joinedAt 오름차순 remainder
  - 전원 실패: systemFee 30% 기록, refundPool 균등 환불(REFUND), joinedAt 오름차순 remainder
  - 정산 후 room.status = SETTLED, RoomMember.status = SUCCESS / FAILED
  - Settlement / SettlementMember DB 저장, PointWallet balance 증가 + PointLedger 양수 이력
- `GET /api/rooms/{roomId}/members/stats` 미션 전체 기간 누적 통계 조회
  - IN_PROGRESS / SETTLED 허용, RECRUITING / READY 409, 비멤버 403
  - CONFIRMED만 성공 인증으로 계산 (SUBMITTED 제외)
  - DAILY: totalRequiredProofCount = durationDays * requiredProofCount
  - WEEKLY: totalRequiredProofCount = (durationDays / 7) * requiredProofCount
  - requiredSuccessCount = ceil(totalRequiredProofCount * targetRate / 100.0)
  - expectedResult: SUCCESS / WAITING_CONFIRM / NEED_MORE / FAILED (응답용, DB 상태 아님)
    - SUCCESS: confirmedCount >= requiredSuccessCount
    - WAITING_CONFIRM: IN_PROGRESS + confirmedCount < requiredSuccessCount + submittedCount >= requiredSuccessCount
    - NEED_MORE: IN_PROGRESS + confirmedCount < requiredSuccessCount + submittedCount < requiredSuccessCount
    - FAILED: SETTLED + confirmedCount < requiredSuccessCount
- `GET /api/rooms/{roomId}/activities` 방 활동 피드 조회 (방 멤버만, 비멤버 403, 없는 방 404)
- `GET /api/notifications` 내 알림 목록 조회 (최신순 50건 고정)
  - 응답: id, roomId(nullable), type, title, message, read(boolean), readAt(nullable), createdAt
- `GET /api/notifications/unread-count` 읽지 않은 알림 수 조회 → { unreadCount }
- `PUT /api/notifications/{notificationId}/read` 단건 읽음 처리 (본인 알림만, 타인 403, 없으면 404, 이미 읽음 200 idempotent)
- `PUT /api/notifications/read-all` 전체 읽음 처리 (JPQL bulk update, 0건이어도 200)
- `POST /api/device-tokens` FCM 토큰 등록/갱신 (로그인 필요, 신규/재활성화/재할당 모두 200 OK)
  - 같은 token + 같은 user → platform 갱신 + active=true (재활성화)
  - 같은 token + 다른 user → 현재 로그인 사용자로 재할당 (기기 전환 대응)
  - token blank → 400, invalid platform → 400
- `DELETE /api/device-tokens` FCM 토큰 비활성화 (request body로 token 전달, 204 No Content)
  - row 삭제 아닌 active=false 처리 (재로그인 시 재활성화 가능)
  - 타인 token 비활성화 → 403, 없는 token → 404
  - createdAt DESC 정렬, 최근 50건 고정 조회
  - 응답: id, roomId, actorId(nullable), actorNickname(nullable), type, message, createdAt
  - MEMBER_JOINED / MEMBER_STAKED / ROOM_READY / ROOM_STARTED / PROOF_SUBMITTED / PROOF_CONFIRMED / ROOM_SETTLED 7종 이벤트 자동 기록
  - 기록 위치: joinRoom / stakeRoom / startRoom / submitProof / confirmProof / settle 성공 직후, 같은 트랜잭션 내
  - ROOM_READY / ROOM_SETTLED는 actor null (시스템 이벤트)
  - actor가 필요한 타입에 null 전달 시 IllegalArgumentException (방어적 처리)
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
  - LedgerType: ROOM_SETTLEMENT_REFUND, ROOM_SETTLEMENT_SUCCESS_BONUS 추가 (ROOM_REFUND 레거시 보존)
  - PointService: addForSettlement() 추가
- `global/storage/` 패키지: `LocalFileStorageService`, `FileUploadResult`
- `global/config/` 패키지: `WebConfig` (/uploads/** 정적 파일 서빙)
- `domain/proof/` 패키지
  - entity: `Proof` (confirm() 추가), `ProofStatus`, `ProofConfirmation`
  - repository: `ProofRepository` (findByIdForUpdate + status count + findByRoomOrderByCreatedAtDesc 추가), `ProofConfirmationRepository` (countByProof 추가)
  - service: `ProofService` (confirmProof() + getProofFeed() 추가), `TodayStatusService`, `MemberStatsService`
  - controller: `ProofController` (GET /{roomId}/proofs 추가), `ProofConfirmController`
  - dto: `ProofSubmitResponse`, `ProofConfirmResponse`, `ProofFeedItemResponse` (신규), `TodayStatusResponse`, `ProofMemberStatusResponse`, `ProofProgressStatus`, `MemberStatsResponse`, `MemberStatsMemberResponse`, `MemberExpectedResult`
- `domain/room/` 패키지
  - entity: `Room` (start() / settle() 추가), `RoomStatus`, `RoomMember` (markSuccess() / markFailed() 추가), `RoomMemberRole`, `RoomMemberStatus`
  - repository: `RoomRepository`, `RoomMemberRepository`
  - service: `RoomService` (createRoom 검증 추가: durationDays >= 28, stakePoint 범위, getRoomDetailEnriched() 추가, getRoomMembers() stakedPoint/stakedAt 포함)
  - controller: `RoomController` (GET /{roomId} → RoomDetailEnrichedResponse 반환, today-status, members/stats 엔드포인트 추가)
  - dto: `RoomCreateRequest`, `RoomSummaryResponse`, `RoomDetailResponse`, `RoomDetailEnrichedResponse`, `RoomInviteResponse`, `RoomMemberResponse` (stakedPoint/stakedAt 추가), `JoinRoomRequest`
- `domain/settlement/` 패키지
  - entity: `Settlement`, `SettlementMember`, `SettlementMemberResult`
  - repository: `SettlementRepository`, `SettlementMemberRepository` (findAllBySettlementOrderByIdAsc 추가)
  - service: `SettlementService` (settle() + getSettlement() 포함, RoomActivityService 주입 추가)
  - controller: `SettlementController`
  - dto: `SettlementResponse`, `SettlementMemberResponse`
- `domain/activity/` 패키지 (신규)
  - entity: `ActivityType` (7종 enum), `RoomActivity` (BaseTime 상속, actor nullable, message length=255)
  - repository: `RoomActivityRepository` (findTop50ByRoomOrderByCreatedAtDesc 추가)
  - service: `RoomActivityService` (record() + getActivities())
  - controller: `RoomActivityController` (GET /{roomId}/activities)
  - dto: `RoomActivityResponse` (static from() 팩토리)
- `RoomService`: RoomActivityService 주입 추가, joinRoom/stakeRoom/startRoom에 record() 연결
- `ProofService`: RoomActivityService 주입 추가, submitProof/confirmProof에 record() 연결
- `domain/notification/` 패키지 (신규)
  - entity: `NotificationType` (4종 enum: PROOF_SUBMITTED/PROOF_CONFIRMED/ROOM_STARTED/ROOM_SETTLED), `Notification` (BaseTime 상속, receiver NOT NULL, room nullable, readAt nullable, markAsRead() idempotent)
  - repository: `NotificationRepository` (findTop50ByReceiverOrderByCreatedAtDesc, countByReceiverAndReadAtIsNull, @Modifying markAllAsRead JPQL bulk)
  - service: `NotificationService` (notify() + getMyNotifications() + getUnreadCount() + markAsRead() + markAllAsRead())
  - controller: `NotificationController` (GET /, GET /unread-count, PUT /{id}/read, PUT /read-all)
  - dto: `NotificationResponse` (static from() 팩토리), `UnreadCountResponse`
- `RoomService`: NotificationService 주입 추가, startRoom에 전 멤버 ROOM_STARTED 알림 연결
- `ProofService`: NotificationService 주입 추가, submitProof에 제출자 제외 전 멤버 PROOF_SUBMITTED 알림, confirmProof에 인증 작성자 PROOF_CONFIRMED 알림 연결
- `SettlementService`: NotificationService 주입 추가, settle에 전 멤버 ROOM_SETTLED 알림 연결
- `domain/device/` 패키지 (신규)
  - entity: `DevicePlatform` (3종 enum: ANDROID/IOS/WEB), `DeviceToken` (BaseTime 상속, token UNIQUE length=512, active boolean, reactivate()/reassign()/deactivate() 메서드)
  - repository: `DeviceTokenRepository` (findByToken, findByUserAndToken, findAllByUserAndActiveTrue)
  - service: `DeviceTokenService` (register() upsert + deactivate() + findActiveTokens() 18-2 예정)
  - controller: `DeviceTokenController` (POST /, DELETE / request body)
  - dto: `DeviceTokenRegisterRequest`, `DeviceTokenDeactivateRequest`, `DeviceTokenResponse`

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
`JOINED, STAKED, SUCCESS, FAILED, SETTLED` — 현재 사용값: `JOINED`, `STAKED`, `SUCCESS`, `FAILED` (SETTLED는 레거시 보존, 미사용)

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

## 8단계 Proof Submit 테스트 완료 내용
- build 성공
- content만 제출 201 확인
- file만 제출 201 (이미지/동영상) 확인
- content + file 동시 제출 201 확인
- start 당일 제출 → 미션 기간 전 409 확인
- content + file 모두 없음 → 400 확인
- 빈 파일 전송 → 400 확인
- 비멤버 요청 → 403 확인
- IN_PROGRESS 아닌 방 → 409 확인
- 제출 수 초과 → 409 확인 (DAILY/WEEKLY)
- uploads/proofs/ 파일 저장 및 /uploads/proofs/{storedName} 접근 확인

## 8단계 보완 완료: ProofService deadlineTime 검증
- Asia/Seoul 기준 nowTime.isAfter(room.deadlineTime)이면 409
- deadlineTime 정각은 허용, 이후만 차단
- deadlineTime 이후 제출 → 409 테스트 완료
- build 성공, 서버 실행 정상

## 9단계 Proof Confirm 테스트 완료 내용
- build 성공, 서버 실행 정상
- 본인 proof 확인 → 403 확인
- 중복 확인 → 409 확인
- 정상 확인 → 200, proof.status CONFIRMED 확인
- 이미 CONFIRMED proof에 새 confirmer 확인 → 200, confirmedAt 유지 확인

## 10단계 Today Status 테스트 완료 내용
- build 성공, 서버 실행 정상
- 비멤버 요청 → 403 확인
- IN_PROGRESS 아닌 방 → 409 확인
- 미션 기간 외(start 당일) → 409 확인
- DAILY/WEEKLY 정상 조회 → 200 확인
- submittedCount / confirmedCount / status 값 확인

## 11단계 Member Stats 테스트 완료 내용
- build 성공, 서버 실행 정상
- 비멤버 요청 → 403 확인
- RECRUITING/READY 방 → 409 확인
- 정상 조회 → 200 확인
- submittedCount / confirmedCount / proofRate / expectedResult 값 확인

## 12단계 Settlement 테스트 완료 내용
- build 성공, 서버 실행 정상
- 비멤버 요청 → 403 확인
- IN_PROGRESS 아닌 방 → 409 확인
- missionEndDate 당일 정산 → 409 확인
- 중복 정산 → 409 확인
- 전원 성공: rewardPoint = stakePoint + bonus, ROOM_SETTLEMENT_REFUND + ROOM_SETTLEMENT_SUCCESS_BONUS 이력 확인
- 일부 성공: 성공자 ROOM_SETTLEMENT_REFUND + ROOM_SETTLEMENT_REWARD, 실패자 rewardPoint = 0 확인
- 전원 실패: systemFee 30% 기록, ROOM_SETTLEMENT_REFUND 환불 이력 확인
- room.status SETTLED, RoomMember SUCCESS/FAILED 전환 확인
- Settlement / SettlementMember DB 저장 확인

## 13단계 Query Support 테스트 완료 내용
- build 성공, 서버 실행 정상
- GET /api/rooms/{roomId} → RoomDetailEnrichedResponse 반환 확인 (ownerId, ownerNickname, myRole, myMemberStatus, createdAt, members 목록 포함)
- GET /api/rooms/{roomId}/members → stakedPoint, stakedAt 포함 확인
- GET /api/rooms/{roomId}/settlement → 정산 전 409 확인, 정산 후 200 + 결과 확인
- 비멤버 GET /api/rooms/{roomId}/settlement → 403 확인

## 14단계 Proof Feed 조회 구현 완료 내용 (백엔드)
- ProofRepository.findByRoomOrderByCreatedAtDesc() 추가
- ProofConfirmationRepository.countByProof() 추가
- ProofFeedItemResponse DTO 신규 생성
- ProofService.getProofFeed() 추가 (readOnly 트랜잭션)
- ProofController GET /{roomId}/proofs 추가
- 빌드 성공 및 Flutter ProofFeedScreen 실제 API 연결 완료

## MVP 완료 검증
- User A / User B 전체 플로우 스모크 테스트 완료
- 방 생성 → 초대 → 참여 → 예치 → 시작 → 인증 제출 → 인증 확인 → 정산 → 포인트 원장 확인 완료
- 일부 성공 정산 케이스 검증 완료
  - A SUCCESS, rewardPoint 2,000P
  - B FAILED, rewardPoint 0P
  - A 최종 101,000P / B 최종 99,000P

## 18-1단계 DeviceToken DB + API 테스트 완료 내용
- 빌드 성공, 서버 실행 정상
- POST /api/device-tokens 신규 token 등록 200 확인
- 같은 token 재등록 (같은 user) → row 중복 없이 updatedAt 갱신 확인
- DELETE /api/device-tokens body {token} → 204, DB active=false 확인
- 비활성화 후 재등록 → active=true 복구 확인
- 다른 사용자로 같은 token 등록 → user 재할당 200 확인
- 타인 token 비활성화 → 403 확인
- 없는 token 비활성화 → 404 확인
- blank token → 400 확인
- invalid platform → 400 확인

## 17단계 Notification DB + API 테스트 완료 내용
- 빌드 성공, 서버 실행 정상
- 방 시작 → 전 멤버 ROOM_STARTED 알림 생성 확인
- 인증 제출 → 제출자 제외 전 멤버 PROOF_SUBMITTED 알림 확인
- 인증 확인 → 인증 작성자 PROOF_CONFIRMED 알림 확인
- 정산 → 전 멤버 ROOM_SETTLED 알림 확인
- GET /api/notifications → 최신순 목록 200 확인
- GET /api/notifications/unread-count → unreadCount 값 확인
- PUT /api/notifications/{id}/read → read true, readAt 설정 확인, 이미 읽음 200 idempotent 확인
- PUT /api/notifications/read-all → 전체 읽음 처리 200 확인
- 타인 알림 읽음 처리 → 403 확인
- 없는 알림 → 404 확인

## 16단계 Room Activity Feed 테스트 완료 내용
- 빌드 성공, 서버 실행 정상
- B 방 참여 → GET activities → MEMBER_JOINED 확인
- A/B 예치 → MEMBER_STAKED 확인, 전원 예치 완료 → ROOM_READY 확인
- 방 시작 → ROOM_STARTED 확인
- 인증 제출 → PROOF_SUBMITTED 확인
- 인증 확인 → PROOF_CONFIRMED 확인
- 정산 → ROOM_SETTLED 확인
- 비멤버 GET activities → 403 확인
- 없는 방 GET activities → 404 확인

## 다음 단계
- 18-2단계: Firebase Admin SDK + FcmService (다음 작업 — 18-1 DeviceToken DB + API 완료)
- 19단계: Room Chat WebSocket/STOMP
- 20단계: Mission Progress Board
- 21단계: Settlement Share Card

## 문서 상태
research: `00_project_baseline`, `01_point`, `02_room_create`, `03_room_join`, `04_room_stake`, `05_room_proof_frequency`, `06_room_start`, `07_local_file_upload`, `08_proof_submit`, `09_proof_confirm`, `10_today_status`, `11_member_stats`, `12_settlement`, `13_query_support`, `14_proof_feed`, `16_room_activity`, `17_notification`, `18_1_device_token`
plan: `00_user_me`, `01_point`, `02_room_create`, `03_room_join`, `04_room_stake`, `05_room_proof_frequency`, `06_room_start`, `07_local_file_upload`, `08_proof_submit`, `09_proof_confirm`, `10_today_status`, `11_member_stats`, `12_settlement`, `13_query_support`, `14_proof_feed`, `15_second_phase`, `16_room_activity`, `17_notification`, `18_1_device_token`
