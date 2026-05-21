# 13_query_support_research.md

## 분석 대상
- GET /api/rooms/{roomId} 보강 — members 목록, ownerId/ownerNickname/myMemberStatus/createdAt 추가
- GET /api/rooms/{roomId}/settlement — 정산 결과 조회 신규

## 기존 조회 API 현황
- GET /api/rooms/{roomId}: RoomDetailResponse (members 없음, ownerId/myMemberStatus/createdAt 없음)
- GET /api/rooms/{roomId}/members: RoomMemberResponse (stakedPoint/stakedAt 없음)
- GET /api/rooms/{roomId}/settlement: 미구현

## 재사용 가능한 기존 코드
- RoomMemberRepository.findAllByRoomOrderByJoinedAtAsc: members 목록 조회
- SettlementRepository.findByRoom(room): 정산 조회
- SettlementMemberRepository: findAllBySettlementOrderByIdAsc 추가 → id ASC = 저장 순서(joinedAt 순)와 일치
- SettlementResponse / SettlementMemberResponse: 요구 필드 전부 포함 → 그대로 재사용

## RoomDetailResponse 분석
- @AllArgsConstructor 18필드, toDetailResponse() 헬퍼를 write 4개 메서드(create/join/stake/start)가 공유
- write 응답 수정 범위 최소화를 위해 GET 전용 RoomDetailEnrichedResponse 신규 생성 권장

## RoomMemberResponse 분석
- 현재: userId, nickname, role, status, joinedAt
- stakedPoint, stakedAt 추가 → GET /rooms/{roomId}/members도 자동 보강

## 정산 조회 검증 조건
- room 없음 → 404, 비멤버 → 403
- settlement 없음 → 409 (방은 존재하지만 정산 미완료 상태)

## inviteCode / inviteLinkToken 정책
- inviteCode: 사용자가 직접 입력하는 6자리 입장 코드
- inviteLinkToken: URL 초대 링크에 들어가는 UUID 기반 토큰
- 둘은 서로 다른 값이며 같은 값으로 매핑하지 않는다.
- RoomDetailEnrichedResponse에는 inviteCode와 inviteLinkToken을 모두 포함한다.
- Room 엔티티에 이미 두 필드 모두 존재 → DB/Entity 추가 없음.

## 금지 확인
- DB 상태 변경 없음, 재정산 없음, PointWallet/Proof/RoomMember 변경 없음
