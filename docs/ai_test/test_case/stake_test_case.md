# Test Case — 예치금 납부 (stakeRoom)

## 기능명
`POST /api/rooms/{roomId}/stake`

## 테스트 대상
`RoomService.stakeRoom(email, roomId)`

## 적용 테스트 레벨
DB 통합 테스트 (`@SpringBootTest + @Transactional`, MySQL checkmate_test)

### 선택 이유
포인트 차감 금액 정합성(wallet.balance, ledger.amount)과 상태 변경(STAKED, READY)이  
하나의 트랜잭션에서 동시에 발생 → Mockito verify()만으로는 금액 정합성 보장 불가.

---

## 성공 케이스 (TC-S)

| ID | 시나리오 | 사전 조건 | 기대 결과 |
|----|----------|----------|----------|
| TC-S-001 | 정상 납부 | RECRUITING 방, JOINED 멤버, 잔액 충분 | balance -= stakePoint, ROOM_STAKE 원장(음수), member.status=STAKED, room.potPoint 증가 |
| TC-S-002 | 전원 납부 → READY 자동 전환 | maxMembers=2, A 납부 후 B 납부 | room.status=READY, room_activities에 ROOM_READY 기록 |

## 실패 케이스 (TC-F)

| ID | 시나리오 | 사전 조건 | 기대 결과 |
|----|----------|----------|----------|
| TC-F-001 | 잔액 부족 | wallet.balance < stakePoint | 400, DB 변동 없음 (wallet/ledger/member 상태 유지) |
| TC-F-002 | 비멤버 납부 | RoomMember 없음 | 403 |
| TC-F-003 | 중복 납부 | member.status=STAKED | 409 |
| TC-F-004 | RECRUITING 아닌 방 | room.status=READY | 409 |

---

## 제외 케이스 및 이유

| 케이스 | 제외 이유 |
|--------|----------|
| FCM 알림 | 예치금 납부 시 notify() 미호출 — 처음부터 대상 아님 |
| RoomActivity 상세 내용 검증 | 기록 여부(건수)만 확인, ActivityType 외 필드는 별도 검증 불필요 |
