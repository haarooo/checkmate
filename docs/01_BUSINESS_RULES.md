# 01_BUSINESS_RULES.md

구현 시 API 문서보다 우선한다.

## Room
- 방은 초대 링크 기반 비공개방만 존재.
- 생성자는 OWNER.
- 생성 직후 status=RECRUITING, 시작/종료일 null.
- maxMembers 인원 모두 참여 + 전원 STAKED이면 READY.
- OWNER만 READY에서 start 가능.
- start 시 missionStartDate=오늘+1일, missionEndDate=start+durationDays-1.
- IN_PROGRESS 이후 참여 불가.
- 공개방 필드, proofType 금지.
- durationDays >= 28 필수 (DAILY/WEEKLY 공통). 미달 시 400.
- WEEKLY 추가 조건: durationDays % 7 == 0. 불일치 시 400.
- stakePoint 최소 1,000P / 최대 50,000P. 범위 위반 시 400.

## Proof
- 방 멤버만 IN_PROGRESS에서 인증 가능.
- 날짜/주차 기준은 Asia/Seoul.
- content 또는 file 중 하나 필수.
- 텍스트만/파일만/둘 다 가능.
- file은 이미지(jpg/jpeg/png/gif/webp) 또는 동영상(mp4/mov/webm) 허용.
- deadlineTime: LocalTime.now(ZoneId.of("Asia/Seoul")).isAfter(room.getDeadlineTime()) → 409.
  deadline 시각 자체는 허용, 이후만 차단.
- 제출 제한 (proofFrequencyType 기준):
  - DAILY: 같은 room+user+proofDate 기준 당일 제출 수 < requiredProofCount이면 제출 가능, 초과 시 409.
  - WEEKLY: Asia/Seoul 기준 월(MONDAY)~일(SUNDAY) 주차 내 같은 room+user 제출 수 < requiredProofCount이면 제출 가능, 초과 시 409.
- 제출 직후 SUBMITTED.
- ProofStatus는 SUBMITTED, CONFIRMED만 허용. REJECTED/EXPIRED/FAILED 추가 금지.
- 작성자 본인 확인 금지: proof.getUser().getId().equals(user.getId()) → 403.
- 중복 ProofConfirmation 금지: 같은 confirmer가 같은 proof를 재확인 시 409.
- 다른 멤버 1명 이상 확인 시 CONFIRMED. confirmedAt은 최초 확인 시각으로 고정 (이후 재확인해도 변경 안 됨).
- 이미 CONFIRMED인 proof에 새로운 confirmer가 확인: ProofConfirmation 저장, confirmedAt 유지, 200 반환 (idempotent).
- 확인은 정산 전까지 가능.
- CONFIRMED만 인증률에 포함.

## Point
- 회원가입 시 100,000P 지급.
- 잔액은 PointWallet, 모든 변동은 PointLedger.
- 차감은 음수, 지급/환불은 양수.
- LedgerType:
  - SIGNUP_BONUS: 회원가입 보너스
  - TEST_CHARGE: 테스트 충전
  - ROOM_STAKE: 예치금 차감 (음수)
  - ROOM_SETTLEMENT_REFUND: 본인 예치금 반환 (전원 성공 stakePoint 반환 / 일부 성공 stakePoint 반환 / 전원 실패 70% 환불 모두 해당)
  - ROOM_SETTLEMENT_REWARD: 일부 성공 케이스에서 실패자 예치금을 성공자에게 분배하는 보상분
  - ROOM_SETTLEMENT_SUCCESS_BONUS: 전원 성공 시 시스템 성공 보너스 (successBonusPoint = min(stakePoint * 10 / 100, 5000))
  - ROOM_REFUND: 레거시 보존 (이번 정산에서 사용 안 함)

## Settlement
- 방 멤버 누구나 실행 가능. 비멤버 403.
- room.status == IN_PROGRESS일 때만 가능. 아닌 경우 409.
- Asia/Seoul 기준 today > missionEndDate일 때만 가능. today <= missionEndDate → 409 (당일 정산 불가).
- Settlement가 이미 존재하면 409.
- 정산은 하나의 트랜잭션. roomRepository.findByIdForUpdate로 row 비관적 락 사용.
- 정산 성공 시 room.status = SETTLED.
- 정산 후 RoomMember.status = SUCCESS 또는 FAILED.
- RoomMemberStatus.SETTLED 값은 이번 정산 로직에서 사용하지 않는다.

### 성공/실패 판단
- CONFIRMED만 성공 인증으로 계산. SUBMITTED 제외.
- DAILY: totalRequiredProofCount = durationDays * requiredProofCount.
- WEEKLY: totalRequiredProofCount = (durationDays / 7) * requiredProofCount.
- requiredSuccessCount = ceil(totalRequiredProofCount * targetRate / 100.0).
- confirmedCount >= requiredSuccessCount → 성공. 미달 → 실패.

### 포인트 분배

**케이스 A — 전원 성공:**
- 각자 stakePoint 반환.
- successBonusPoint = min(stakePoint * 10 / 100, 5000).
- rewardPoint = stakePoint + successBonusPoint.
- systemBonusPoint = successBonusPoint * totalMembers → Settlement 기록용, 지갑 이동 없음.
- Ledger 기록:
  - stakePoint 반환: ROOM_SETTLEMENT_REFUND
  - successBonusPoint 지급: ROOM_SETTLEMENT_SUCCESS_BONUS

**케이스 B — 일부 성공 / 일부 실패:**
- 성공자: stakePoint 반환 + failedPot 균등 분배.
- failedPot = 실패자 stakePoint 총합.
- bonusPerWinner = failedPot / successCount.
- remainder = failedPot % successCount → joinedAt 오름차순 성공자에게 1P씩 추가.
- 성공자 rewardPoint = stakePoint + bonusPerWinner + 추가분.
- 실패자 rewardPoint = 0. 시스템 성공 보너스 없음.
- Ledger 기록:
  - 성공자 stakePoint 반환: ROOM_SETTLEMENT_REFUND
  - 실패자 예치금 분배 보상: ROOM_SETTLEMENT_REWARD

**케이스 C — 전원 실패:**
- systemFeePoint = potPoint * 30 / 100.
- refundPool = potPoint - systemFeePoint.
- refundPerMember = refundPool / totalMembers.
- remainder = refundPool % totalMembers → joinedAt 오름차순 멤버에게 1P씩 추가.
- 각 멤버 refundPoint = refundPerMember + 추가분.
- systemFeePoint는 지갑 이동 없이 Settlement 기록에만 저장.
- Ledger 기록:
  - refundPoint 지급: ROOM_SETTLEMENT_REFUND

### 포인트 처리 원칙
- Stake에서 이미 차감 완료 → Settlement에서 재차감 없음.
- 지급/환불/보너스는 PointWallet balance 증가 + PointLedger 양수 이력.

### 정산 저장 순서
1. roomRepository.findByIdForUpdate (비관적 락)
2. 조건 검증
3. 성공/실패 분류 및 rewardPoint 계산
4. Settlement 생성 후 save
5. SettlementMember 생성 후 save
6. PointWallet 증가 + PointLedger 저장
7. RoomMember.status → SUCCESS / FAILED
8. Room.status → SETTLED
