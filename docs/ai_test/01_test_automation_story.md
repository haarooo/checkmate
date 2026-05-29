# Story 1. AI 구현 이후의 검증까지 자동화

## 기존 방식

초기에는 AI가 기능을 구현하면 개발자가 직접 clean build, Swagger API 테스트, DB 결과 확인으로 검증했다.
기능 하나 구현할 때마다 같은 시나리오를 반복했다.

## 문제

기능이 늘어날수록 같은 시나리오를 반복 검증해야 했다.
특히 정산·인증·포인트처럼 상태와 금액이 얽힌 기능은 회귀 버그 위험이 높았다.

예:
- 정산 후 PointWallet 잔액이 정확한가?
- PointLedger에 REFUND와 SUCCESS_BONUS가 각각 기록됐는가?
- RoomMember 상태가 SUCCESS/FAILED로 정확히 바뀌었는가?

이를 매번 Swagger로 확인하는 것은 시간이 걸리고, 일부 케이스는 빠뜨릴 수 있었다.

## 개선 방식

기능 구현 후 AI가 아래 흐름을 수행하도록 파이프라인을 만들었다.

1. 기능 유형과 위험도 분석
2. 테스트 레벨 선택 (단위/서비스/DB통합/API/Mock/Smoke)
3. 테스트 케이스 도출
4. 테스트 코드 작성
5. `./gradlew test` 실행
6. 실패 시 원인 분석 및 수정
7. 성공 시 완료 보고서 작성

## 테스트 전략 판단 기준

기능 유형에 따라 테스트 레벨을 선택한다.

- DB 저장 / 트랜잭션 / 데이터 정합성 → DB 통합 테스트 (SpringBootTest + MySQL)
- 상태 변경 / 비즈니스 정책 → 서비스 테스트 (Mockito)
- 계산/분기 로직 → 단위 테스트
- FCM / 외부 연동 → Mock + Smoke 테스트 (수동)

AI가 전략을 제안하고 개발자가 승인한 뒤 테스트 코드를 작성한다.

## 첫 적용 도메인: Settlement

정산은 포인트·원장·방 상태·멤버 상태·알림 DB가 하나의 트랜잭션에서 함께 바뀐다.
Mockito의 `verify()` 호출 확인만으로는 실제 금액 정합성을 보장할 수 없다.
따라서 `@SpringBootTest` + MySQL 기반 DB 통합 테스트를 첫 적용 대상으로 선택했다.

검증 대상:
- rooms.status = SETTLED
- room_members.status = SUCCESS / FAILED
- settlements 테이블 저장
- point_wallets balance 변경
- point_ledgers REFUND + SUCCESS_BONUS 기록
- notifications 생성

## Trade-off

- 초기 테스트 작성 시간 증가
- DB 통합 테스트는 MySQL 환경 필요 (GitHub Actions에서 service container로 해결)
- FCM 실제 발송은 CI 안정성을 위해 자동 테스트 제외

## 결과

- 핵심 도메인의 회귀 검증 자동화
- 수동 Swagger 반복 검증 감소
- 기능 유형에 맞는 테스트 전략 선택 체계 확립
- GitHub Actions CI 연동으로 PR마다 자동 테스트 실행
