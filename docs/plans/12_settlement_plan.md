# 12_settlement_plan.md

## 목표
POST /api/rooms/{roomId}/settle — 정산 실행 (방 멤버 누구나)

## 전제 조건 검증 (SettlementService)
1. roomRepository.findByIdForUpdate(roomId) 404
2. 비멤버 403
3. room.status != IN_PROGRESS 409
4. today(Asia/Seoul) <= missionEndDate 409
5. settlementRepository.findByRoom(room).isPresent() 409

## 기존 파일 수정
- RoomService.createRoom(): durationDays < 28 → 400, stakePoint < 1000 or > 50000 → 400, WEEKLY durationDays % 7 != 0 → 400
- Room.java: settle() 추가 (status = SETTLED)
- RoomMember.java: markSuccess() / markFailed() 추가
- LedgerType.java: ROOM_SETTLEMENT_REFUND, ROOM_SETTLEMENT_SUCCESS_BONUS 추가
  (ROOM_REFUND / RoomMemberStatus.SETTLED 삭제 안 함)
- PointService.java: addForSettlement(user, amount, roomId, LedgerType, description) 추가

## 신규 파일 (domain/settlement/)
1. SettlementMemberResult.java (enum: SUCCESS, FAILED)
2. Settlement.java: id, room, totalPotPoint, totalMembers, successCount, failedCount,
   totalRequiredProofCount, requiredSuccessCount, systemFeePoint, systemBonusPoint, settledAt + BaseTime
3. SettlementMember.java: id, settlement, room, user, resultStatus, submittedCount,
   confirmedCount, requiredSuccessCount, rewardPoint, proofRate + BaseTime
4. SettlementRepository.java: findByRoom(Room) Optional
5. SettlementMemberRepository.java: findAllBySettlement(Settlement)
6. SettlementResponse.java (dto)
7. SettlementMemberResponse.java (dto)
8. SettlementService.java: settle() @Transactional
9. SettlementController.java: POST /api/rooms/{roomId}/settle

## SettlementService 핵심 흐름
1. findByIdForUpdate → 검증 5단계
2. 멤버 순회 → confirmedCount 계산 → SUCCESS/FAILED 분류
3. 케이스 분기:
   - 전원 성공: ROOM_SETTLEMENT_REFUND(stakePoint) + ROOM_SETTLEMENT_SUCCESS_BONUS(bonus) 각각 저장
   - 일부 성공: 성공자 ROOM_SETTLEMENT_REFUND(stakePoint) + ROOM_SETTLEMENT_REWARD(분배분) 각각 저장
   - 전원 실패: ROOM_SETTLEMENT_REFUND(refundPoint) 저장
4. Settlement.save() → SettlementMember.save() (순서 보장)
5. PointWallet.addBalance() + PointLedger.save() (멤버별)
6. RoomMember.markSuccess() / markFailed()
7. Room.settle()

## 검증
- ./gradlew.bat clean build
- 비멤버 403 / missionEndDate 당일 409 / 중복 정산 409
- 전원 성공: rewardPoint = stakePoint + bonus, ROOM_SETTLEMENT_REFUND(stakePoint) + ROOM_SETTLEMENT_SUCCESS_BONUS(bonus) 이력 확인
- 일부 성공: failedPot 분배, remainder 1P 확인, ROOM_SETTLEMENT_REWARD 이력
- 전원 실패: systemFee 30%, refundPool 균등, ROOM_SETTLEMENT_REFUND 이력
- room.status SETTLED, RoomMember SUCCESS/FAILED 확인
