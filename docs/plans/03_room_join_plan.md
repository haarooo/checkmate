# 03_room_join_plan.md

## 목표
GET /api/rooms/invite/{inviteCode} (비로그인), POST /api/rooms/{roomId}/join, GET /api/rooms/{roomId}/members 구현

## 신규 파일
- dto: RoomInviteResponse, RoomMemberResponse

## 수정 파일
- SecurityConfig: GET /api/rooms/invite/** permitAll 1줄 추가만
- RoomMember: createMember() factory 추가
- RoomRepository: findByInviteCode(String) 추가
- RoomMemberRepository: findAllByRoom(Room) 추가
- RoomService: getRoomByInviteCode / joinRoom / getRoomMembers 추가
- RoomController: 3개 엔드포인트 추가

## 수정 금지
SecurityConfig의 다른 설정, JWT, User, Point, Proof, Settlement, build.gradle, application.properties

## 핵심 규칙
- invite: 없는 코드 → 404, joinable = (status==RECRUITING && currentCount < maxMembers)
- join: RECRUITING 아님 → 409 / 중복 → 409 / maxMembers 초과 → 409
- join 성공: role=MEMBER, status=JOINED, stakedPoint=0, joinedAt=now, stakedAt=null
- /members: 방 없음 → 404 / 비멤버 → 403
- proofType, isPublic 필드 생성 금지

## 제외
stake, start, Proof, Settlement, ShareCard

## 검증
./gradlew.bat clean build → Swagger: 비로그인 invite조회 → 로그인 후 join → members 확인
