# 02_room_create_plan.md

## 목표
POST /api/rooms, GET /api/rooms, GET /api/rooms/{roomId} 구현.
Room + 최소 RoomMember 구조(OWNER 등록) 포함.

## 신규 파일
- entity: Room, RoomStatus, RoomMember, RoomRole, RoomMemberStatus
- repository: RoomRepository, RoomMemberRepository
- dto: RoomCreateRequest, RoomSummaryResponse, RoomDetailResponse
- service: RoomService
- controller: RoomController

## 수정 파일
없음. User/Point 도메인 수정 금지.

## 핵심 규칙
- proofType, is_public 필드 금지 (Entity/DB 모두)
- inviteCode: UUID 8자, existsByInviteCode 충돌 확인 후 저장
- 생성 시 status=RECRUITING, potPoint=0, missionStartDate/EndDate=null
- RoomMember: role=OWNER, status=JOINED, joinedAt=now() 으로 등록
- GET /api/rooms: 내가 속한 방만 반환
- GET /api/rooms/{roomId}: 비멤버 요청 → 403

## 제외
invite/{inviteCode} / join / stake / start / Proof / Settlement / ShareCard

## 검증
./gradlew.bat clean build 성공 후 Swagger:
POST /api/rooms → 201, GET /api/rooms → 목록 1건, GET /api/rooms/{id} → 상세
