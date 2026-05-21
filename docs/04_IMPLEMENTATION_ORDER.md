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
8. Proof Submit: content/file 중 하나 필수, DAILY/WEEKLY 기준별 requiredProofCount 제출 제한, deadlineTime 이후 제출 불가(409), SUBMITTED.
9. Proof Confirm: 방 멤버만, 본인 확인 금지(403), 중복 ProofConfirmation 금지(409), CONFIRMED 전환, ProofRepository.findByIdForUpdate.
10. Today Status: 현재 기간 인증 현황 조회.
    - DAILY는 오늘 기준, WEEKLY는 월요일~일요일 기준.
    - submittedCount, confirmedCount, remainingSubmitCount, remainingConfirmCount, deadlinePassed 계산.
    - 상태: SUCCESS / WAITING_CONFIRM / NEED_SUBMIT / MISSED.
11. Member Stats: 인증률, 성공 필요 횟수, 예상 결과.
12. Settlement:
    - Room Create 검증 추가: durationDays >= 28, stakePoint 1,000~50,000.
    - POST /api/rooms/{roomId}/settle: 방 멤버 누구나, 비관적 락(findByIdForUpdate).
    - 성공/실패 판단: CONFIRMED 기준, requiredSuccessCount 비교.
    - 분배: 전원 성공(REFUND+BONUS) / 일부 성공(REFUND+REWARD) / 전원 실패(REFUND 30% 패널티 후 환불).
    - 신규 LedgerType: ROOM_SETTLEMENT_REFUND, ROOM_SETTLEMENT_SUCCESS_BONUS.
    - 신규 Entity: Settlement, SettlementMember.
    - 정산 저장 순서: Settlement → SettlementMember → PointWallet/PointLedger → RoomMember → Room.
13. Query Support:
    - GET /api/rooms/{roomId} 보강: ownerId, ownerNickname, myMemberStatus, createdAt, members 추가.
    - GET /api/rooms/{roomId}/settlement 신규: 비멤버 403, 정산 전 409.
    - RoomDetailEnrichedResponse 신규, RoomMemberResponse stakedPoint/stakedAt 추가.
    - SettlementMemberRepository: findAllBySettlementOrderByIdAsc 추가.
14. ShareCard Data: 정산 후 개인/그룹 카드 데이터.

## Post-MVP 후보
- 조기 종료: 최대 달성 가능 confirmed 수 계산, 조기 종료 가능 여부 조회, 조기 종료 정산.
