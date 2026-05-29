# Test Result — 예치금 납부 (stakeRoom)

## 실행 일시
2026-05-30

## 실행 명령어
```bash
./gradlew.bat test --tests "com.example.checkmate.domain.room.StakeIntegrationTest"
```

---

## 테스트 결과 요약

| 항목 | 결과 |
|------|------|
| 전체 테스트 수 | 6 |
| 성공 | 6 |
| 실패 | 0 |
| 스킵 | 0 |
| build 결과 | SUCCESS |
| 총 실행 시간 | 13.049s |

---

## 성공한 테스트 목록

| 테스트명 | 소요 시간 |
|----------|----------|
| TC-S-001: 정상 납부 — balance 차감, ROOM_STAKE 원장, STAKED 상태, potPoint 증가 | 0.078s |
| TC-S-002: 전원 납부 완료 — room.status READY 자동 전환, ROOM_READY 활동 기록 | 0.163s |
| TC-F-001: 잔액 부족 — 400, wallet/ledger/member 상태 변동 없음 | 0.058s |
| TC-F-002: 비멤버 납부 — 403 | 0.045s |
| TC-F-003: 중복 납부 (이미 STAKED) — 409 | 0.054s |
| TC-F-004: RECRUITING 아닌 방 (READY) — 409 | 1.083s |

---

## 최종 판단

- [x] 정상 구현 완료 — 모든 테스트 통과
- [ ] 수정 후 재실행 필요
- [ ] 후속 테스트 필요

## 남은 리스크

| 항목 | 내용 |
|------|------|
| FCM | 예치금 납부 시 FCM 없음 — 설계 의도대로, 검증 불필요 |
| 비관적 락 동시성 | `findByIdForUpdate` 동시 납부 시나리오는 자동 테스트 미포함 (수동 확인 필요) |
