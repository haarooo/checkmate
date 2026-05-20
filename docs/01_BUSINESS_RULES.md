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
- ProofStatus는 SUBMITTED, CONFIRMED만 허용. REJECTED/EXPIRED 금지.
- 작성자 본인 확인 금지: proof.getUser().getId().equals(user.getId()) → 403.
- 중복 ProofConfirmation 금지: 같은 confirmer가 같은 proof를 재확인 시 409.
- 다른 멤버 1명 이상 확인 시 CONFIRMED. confirmedAt은 최초 확인 시각으로 고정 (이후 재확인해도 변경 안 됨).
- 이미 CONFIRMED인 proof에 새로운 confirmer가 확인: ProofConfirmation 저장, confirmedAt 유지, 200 반환 (idempotent).
- 확인은 정산 전까지 가능. 정산 이후 confirm 금지는 Settlement 단계에서 처리.
- CONFIRMED만 인증률에 포함.

## Point
- 회원가입 시 100,000P 지급.
- 잔액은 PointWallet, 모든 변동은 PointLedger.
- 차감은 음수, 지급/환불은 양수.
- LedgerType: SIGNUP_BONUS, TEST_CHARGE, ROOM_STAKE, ROOM_SETTLEMENT_REWARD, ROOM_REFUND.

## Settlement
- missionEndDate 이후 1회만.
- proofRate=confirmedCount/durationDays*100.
- targetRate 이상 SUCCESS.
- 성공자 있으면 potPoint 균등 분배.
- 전원 실패 시 전원 환불.
- 정산은 하나의 트랜잭션.
