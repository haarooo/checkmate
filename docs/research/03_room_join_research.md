# 03_room_join_research.md

## 기존 코드 확인
- RoomMember: createOwner() 있음 → createMember() 추가 필요
- RoomMemberRepository: findByRoomAndUser, countByRoom 이미 존재 → findAllByRoom() 추가 필요
- RoomRepository: existsByInviteCode 있음 → findByInviteCode() 추가 필요
- RoomService: toDetailResponse, findUserByEmail 헬퍼 재사용 가능
- SecurityConfig: permitAll 목록에 GET /api/rooms/invite/** 추가 필요 (이번 단계 예외 허용)

## 핵심 검증 규칙
- invite 조회: 없으면 404, 인증 불필요, 민감정보 제외
- join: status != RECRUITING → 409 / 중복 → 409 / maxMembers 초과 → 409
- GET /members: 방 없으면 404, findByRoomAndUser 없으면 403

## 응답 설계
- GET /invite/{inviteCode} → RoomInviteResponse (비로그인 허용)
  포함: roomId, title, description, status, durationDays, deadlineTime, targetRate, stakePoint, maxMembers, currentMemberCount, joinable
  제외: owner email, memberList, 개인정보
- POST /join → RoomDetailResponse 200 OK
- GET /members → List<RoomMemberResponse> (id, nickname, role, status, joinedAt)

## 수정 파일
- SecurityConfig: GET /api/rooms/invite/** permitAll 추가만
- RoomMember: createMember() 추가
- RoomRepository: findByInviteCode() 추가
- RoomMemberRepository: findAllByRoom() 추가
- RoomService / RoomController: 3개 메서드/엔드포인트 추가
