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
- 날짜 기준은 Asia/Seoul.
- content 또는 image 중 하나 필수.
- 텍스트만/이미지만/둘 다 가능.
- 같은 방+사용자+날짜 인증 1개.
- 제출 직후 SUBMITTED.
- 작성자 본인 확인 금지.
- 다른 멤버 1명 이상 확인 시 CONFIRMED.
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
