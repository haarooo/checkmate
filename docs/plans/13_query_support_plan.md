# 13_query_support_plan.md

## 목표
GET /api/rooms/{roomId} 보강, GET /api/rooms/{roomId}/settlement 신규

## 수정 파일

### RoomMemberResponse.java
stakedPoint(long), stakedAt(LocalDateTime) 필드 추가
getRoomMembers() 호출부에서 m.getStakedPoint(), m.getStakedAt() 매핑

### RoomDetailEnrichedResponse.java (신규 dto)
필드: roomId, title, description, status,
      inviteCode (6자리 직접 입력 코드),
      inviteLinkToken (URL 초대 링크 토큰),
      ownerId, ownerNickname, myRole, myMemberStatus,
      proofFrequencyType, requiredProofCount,
      durationDays, deadlineTime, targetRate, stakePoint, maxMembers,
      currentMemberCount, potPoint, missionStartDate, missionEndDate,
      createdAt, List<RoomMemberResponse> members

### SettlementMemberRepository.java
findAllBySettlementOrderByIdAsc(Settlement) 추가
(id ASC = 정산 시 joinedAt 순 저장 순서와 일치)

### RoomService.java
- getRoomDetailEnriched(email, roomId) @Transactional(readOnly=true) 추가
  검증: room 404 → 비멤버 403 → members 전체 조회 → DTO 조립
- getRoomMembers(): stakedPoint, stakedAt 추가 매핑

### RoomController.java
GET /{roomId} → roomService.getRoomDetailEnriched() 호출, 반환 타입 RoomDetailEnrichedResponse

### SettlementService.java
getSettlement(email, roomId) @Transactional(readOnly=true) 추가
검증: room 404 → 비멤버 403 → settlement 없으면 409
findAllBySettlementOrderByIdAsc → SettlementResponse 반환

### SettlementController.java
GET /{roomId}/settlement 추가

## 검증
- ./gradlew.bat clean build
- 비멤버 GET /rooms/{roomId} → 403
- roomId, ownerId, ownerNickname, myMemberStatus, inviteCode, inviteLinkToken, members, createdAt 포함 확인
- GET /rooms/{roomId}/members에서 stakedPoint, stakedAt 포함 확인
- 정산 전 GET /settlement → 409
- 정산 후 GET /settlement → 200, 전 필드 및 members 순서 확인
