# 04_IMPLEMENTATION_ORDER.md

한 번에 한 단계만 구현한다.

## 공통
문서 읽기 → 코드 분석 → research 작성 → plan 작성 → 승인 대기 → 구현 → build → Swagger 테스트 → CURRENT_STATE 갱신.

## 순서
1. User me API 수정: `/api/users/me` JSON 응답, password 제외.
2. PointWallet / PointLedger: 가입 보너스 100,000P, 잔액/이력 조회.
3. Room 생성: RECRUITING, inviteCode, OWNER 등록, proofType 금지.
4. RoomMember / Join: 초대 조회, 참여, 중복/인원 제한.
5. Stake: 포인트 차감, Ledger 기록, 전원 STAKED 시 READY.
6. Start: OWNER만, READY만, 다음 날 시작, IN_PROGRESS.
7. Local File Upload: MultipartFile, UUID 파일명, 로컬 저장.
8. Proof Submit: content/image 중 하나 필수, 하루 1회, SUBMITTED.
9. Proof Confirm: 본인 확인 금지, 중복 금지, CONFIRMED 전환.
10. Today Status: RoomMember 기준 CONFIRMED/SUBMITTED/NOT_SUBMITTED.
11. Member Stats: 인증률, 성공 필요 횟수, 예상 결과.
12. Settlement: 자동 성공 판정, 포인트 분배/환불, SETTLED.
13. ShareCard Data: 정산 후 개인/그룹 카드 데이터.
