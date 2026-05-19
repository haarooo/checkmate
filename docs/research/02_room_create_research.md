# 02_room_create_research.md

## DB 핵심 확인
- rooms: status, invite_code(UNIQUE), pot_point, mission_start/end_date → 생성 시 null
- room_members: role, status, staked_point, joined_at, staked_at + BaseTime(created/updated)
- rooms에 proof_type, is_public 컬럼 금지

## 비즈니스 규칙 (이번 단계)
- 생성 직후: status=RECRUITING, missionStartDate/EndDate=null, potPoint=0
- 생성자: RoomMember role=OWNER, status=JOINED, joinedAt=now(), stakedAt=null
- inviteCode: UNIQUE 보장 필요 → UUID 8자, 충돌 시 재생성 루프

## 쿼리 설계
- GET /api/rooms: RoomMemberRepository.findByUser(user) → 소속 방 목록
- GET /api/rooms/{roomId}: roomId로 Room 조회 후, 멤버십 확인(비멤버 403) → 반환
- 현재 인원수: RoomMemberRepository.countByRoom(room)

## 이번 단계 제외
- invite/{inviteCode}, join, stake, start 미구현
- joined_at, staked_at 이후 단계에서 의미 있는 값 사용 → 지금은 JOINED 등록만

## 패턴 참조
- Entity: @Getter, @NoArgsConstructor(PROTECTED), static factory method
- Service: email → user 조회, 쓰기 @Transactional / 읽기 @Transactional(readOnly=true)
- Controller: Authentication.getName() → Service 위임
