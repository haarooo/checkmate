# Test Strategy Decision — Settlement 정산

## 기능명
Settlement 정산 (`POST /api/rooms/{roomId}/settle`)

## 요청 내용 요약
정산 기능 구현 이후 반복 Swagger 검증을 테스트 코드 기반 검증으로 전환.
전원 성공 / 일부 성공 / 전원 실패 / 중복 정산 / 미션 종료 전 정산 5가지 케이스 검증.

## 기능 유형
- [x] DB 저장 / 트랜잭션 / 데이터 정합성
- [x] 상태 변경 (방 상태, 멤버 상태)
- [x] 포인트/원장 변경 (금액 정합성)

## 영향 도메인
Room, RoomMember, Settlement, SettlementMember, PointWallet, PointLedger, Notification

## 변경되는 데이터

| 테이블 | 변경 내용 |
|--------|----------|
| rooms | status → SETTLED |
| room_members | status → SUCCESS / FAILED |
| settlements | 신규 row 생성 |
| settlement_members | 멤버별 결과 저장 |
| point_wallets | balance 증가 |
| point_ledgers | REFUND / SUCCESS_BONUS / REWARD 원장 생성 |
| notifications | 멤버별 ROOM_SETTLED 알림 저장 |

## 외부 연동 여부
- FCM: Y (NotificationFcmEventListener → AFTER_COMMIT 발송)

## AI 제안 테스트 레벨

| 레벨 | 선택 | 이유 |
|------|------|------|
| 단위 테스트 | — | 7개 테이블 동시 변경 → 격리 검증 불충분 |
| 서비스 테스트 (Mockito) | — | verify() 호출 여부만 확인, 실제 금액 정합성 보장 불가 |
| **DB 통합 테스트** | **✓** | 실제 MySQL DB 상태 변화까지 검증 필요 |
| API 테스트 | — | HTTP 응답 코드보다 DB 정합성이 핵심 |
| Mock 테스트 | — | FCM 이벤트 자체는 AFTER_COMMIT이므로 자동 배제 |
| Smoke 테스트 | FCM만 | FCM 실제 발송은 개발 환경 수동 확인 |

## 제외한 테스트와 제외 이유

| 레벨 | 제외 이유 |
|------|----------|
| Mockito verify() | 금액/잔액 정합성은 실제 DB 저장 후에만 확인 가능 |
| FCM 실제 발송 자동 테스트 | 외부 Firebase 의존·service account·실 push 위험·CI 안정성 저하 |

## 선택 이유 상세

Settlement는 하나의 트랜잭션에서 아래 7개 테이블이 동시에 바뀐다.
`verify()`로 메서드 호출 여부만 확인하는 Mockito 테스트는 실제 저장된 금액이 맞는지 보장하지 못한다.
예를 들어 `addForSettlement()`가 호출됐다고 해도, 잘못된 금액(stakePoint * 10/100 vs 30/100)이 들어갈 수 있다.
DB 통합 테스트에서 `pointWalletRepository.findByUser(user).getBalance()`를 직접 확인해야 회귀 버그를 잡을 수 있다.

## 개발자 승인
- [x] 승인 (DB 통합 테스트 채택)
