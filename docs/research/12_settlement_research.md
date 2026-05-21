# 12_settlement_research.md

## 분석 대상
POST /api/rooms/{roomId}/settle — 방 정산 실행 (방 멤버 누구나)

## 기존 코드 재사용
- RoomRepository.findByIdForUpdate 패턴: startRoom과 동일하게 비관적 락 적용
- MemberStatsService 성공/실패 판단 로직 동일 (confirmedCount >= requiredSuccessCount)
- ProofRepository 카운트 메서드: missionStartDate~missionEndDate 범위 + CONFIRMED 조건 재사용
- RoomMemberRepository.findAllByRoomOrderByJoinedAtAsc: joinedAt 오름차순 remainder 분배용
- PointService.deductForRoomStake 구조 참고 → addForSettlement 메서드 추가

## 정산 가능 조건 검증
- room 404 → 비멤버 403 → room.status != IN_PROGRESS 409
- Asia/Seoul today <= missionEndDate → 409
- settlementRepository.findByRoom(room).isPresent() → 409

## 성공/실패 판단 (MemberStats와 동일)
- DAILY: totalRequired = durationDays * requiredProofCount
- WEEKLY: totalRequired = (durationDays / 7) * requiredProofCount
- requiredSuccess = (int) Math.ceil(total * targetRate / 100.0)
- confirmedCount >= requiredSuccess → SUCCESS, 미달 → FAILED

## 3가지 분배 케이스
- A 전원 성공: stakePoint + min(stakePoint * 10/100, 5000) / systemBonusPoint 기록
- B 일부 성공: 성공자 stakePoint + failedPot 균등, joinedAt 오름차순 remainder
- C 전원 실패: systemFee 30%, refundPool 균등, joinedAt 오름차순 remainder

## LedgerType 현황 확인
- 기존 선언: ROOM_SETTLEMENT_REWARD(미사용), ROOM_REFUND(미사용)
- 이번에 추가: ROOM_SETTLEMENT_REFUND(신규), ROOM_SETTLEMENT_SUCCESS_BONUS(신규)
- ROOM_SETTLEMENT_REFUND: 예치금 반환 전 케이스 공통 (A stakePoint / B stakePoint / C refundPool)
- ROOM_SETTLEMENT_REWARD: 일부 성공 케이스 실패자 예치금 분배 보상만 해당 (기존 재사용)
- ROOM_SETTLEMENT_SUCCESS_BONUS: 전원 성공 시 시스템 보너스 (신규)
- ROOM_REFUND: 삭제 안 함. 이번 정산에서 사용 안 함.

## RoomMemberStatus 현황 확인
- 현재 enum: JOINED, STAKED, SUCCESS, FAILED, SETTLED
- SETTLED 삭제 안 함. 이번 정산에서 사용 안 함.
- 정산 후: RoomMember.status = SUCCESS 또는 FAILED

## 동시성 처리
- roomRepository.findByIdForUpdate로 row 비관적 락 획득
- 같은 트랜잭션 내에서 Settlement 존재 여부 확인 후 정산 수행
- settlements.room_id UNIQUE는 DB 레벨 보조 안전장치

## 신규 파일 (domain/settlement/)
- SettlementMemberResult.java (enum: SUCCESS, FAILED)
- Settlement.java, SettlementMember.java (entity)
- SettlementRepository.java, SettlementMemberRepository.java
- SettlementService.java, SettlementController.java
- SettlementResponse.java, SettlementMemberResponse.java (dto)

## 기존 파일 수정 대상
- LedgerType.java: ROOM_SETTLEMENT_REFUND, ROOM_SETTLEMENT_SUCCESS_BONUS 추가
- Room.java: settle() 메서드 추가
- RoomMember.java: markSuccess() / markFailed() 추가
- PointService.java: addForSettlement(user, amount, roomId, type, description) 추가
- RoomService.createRoom(): durationDays < 28 → 400, stakePoint 범위 검증 추가
