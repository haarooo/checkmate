# test_strategy_matrix.md

AI가 기능 구현 후 테스트 전략을 선택할 때 사용하는 기준표다.
AI는 이 기준표를 바탕으로 전략을 제안하고, 개발자가 승인한 뒤 테스트 코드 작성을 진행한다.

---

## 테스트 레벨 정의

| 레벨 | 도구 | 설명 |
|------|------|------|
| 단위 테스트 | JUnit + Mockito | 단일 메서드/클래스 로직만 검증. Spring Context 불필요 |
| 서비스 테스트 | JUnit + Mockito | Service 레이어 비즈니스 로직 검증. DB 미사용 |
| DB 통합 테스트 | SpringBootTest + MySQL | 실제 DB에 저장·조회·트랜잭션 검증 |
| API 테스트 | SpringBootTest + MockMvc | HTTP 요청/응답, 인증, 권한 검증 |
| Mock 테스트 | Mockito / MockBean | 외부 연동(FCM, S3 등) 의존성 제거 후 검증 |
| Smoke 테스트 | 수동 | 개발 환경에서 핵심 흐름 동작 확인 |
| E2E 테스트 | 수동 / 별도 도구 | 사용자 전체 플로우 검증 |

---

## 기능 유형별 테스트 레벨 선택 기준

| 기능 유형 | 권장 레벨 | 이유 |
|-----------|----------|------|
| 계산/분기 로직 (포인트 계산, 보너스 공식 등) | 단위 테스트 | 외부 의존 없음, 빠른 검증 가능 |
| 상태 변경 / 비즈니스 정책 (상태 전환, 권한) | 서비스 테스트 (Mockito) | 핵심 로직만 격리, DB 불필요 |
| DB 저장 / 트랜잭션 / 데이터 정합성 | DB 통합 테스트 | 실제 저장 여부와 금액 정합성을 검증해야 함 |
| 인증 / 권한 / HTTP 응답 코드 | API 테스트 (MockMvc) | Filter Chain, Security, HTTP 코드 포함 |
| FCM / 외부 API / STOMP | Mock 테스트 + Smoke | 외부 서비스 의존, CI 안정성 저하 방지 |
| 핵심 사용자 플로우 (회원가입→방생성→인증→정산) | E2E 테스트 (수동) | 자동화 비용 대비 수동 검증 우선 |

---

## Checkmate 도메인별 기본 테스트 전략

| 도메인 | 전략 | 핵심 검증 대상 |
|--------|------|--------------|
| **Settlement** | DB 통합 테스트 우선 | 포인트·원장·방상태·멤버상태·알림 동시 변경 → 정합성 |
| **Proof** | API + DB 통합 | 제출 제한(DB 조회 의존), 기간/권한, Multipart |
| **Point** | DB 통합 | 잔액·원장 정합성, 금액 오차 시 실 피해 |
| **Room** | 서비스 테스트 + API 테스트 | 상태 전환 흐름 (RECRUITING→READY→IN_PROGRESS→SETTLED) |
| **Notification** | DB 통합 (FCM 제외) | Notification row 저장 확인, FCM 발송은 제외 |
| **FCM** | Smoke 테스트 (수동) | 실 발송 CI 안정성 위험, service account 필요 |
| **STOMP / Chat** | 서비스 테스트 + Smoke | 메시지 저장·권한 검증, WebSocket 연결은 수동 |
| **File Upload** | API 테스트 | Multipart 처리, 파일 메타데이터 저장 검증 |

---

## FCM 자동 테스트 제외 기준

FCM 실제 발송은 아래 이유로 자동 테스트 범위에서 제외한다.

- 외부 Firebase 서비스 의존
- service account JSON 파일 필요 (CI 환경 노출 위험)
- 실 기기에 push 발송될 수 있음
- CI 실패 원인이 비즈니스 로직 오류인지 Firebase 연결 문제인지 구분 어려움

대신: Notification DB 저장까지만 자동 검증. FCM 발송은 개발 환경 수동 Smoke 테스트로 분리.

---

## 테스트 레벨 선택 가이드

AI가 기능 구현 후 테스트 전략을 판단할 때 아래 질문에 답해 레벨을 결정한다.

1. 이 기능에서 바뀌는 DB 테이블이 2개 이상인가? → DB 통합 테스트
2. 포인트/금액이 변경되는가? → DB 통합 테스트 (잔액 정합성 필수)
3. HTTP 인증/권한이 핵심인가? → API 테스트
4. 외부 서비스(FCM, S3 등)가 포함되는가? → Mock + Smoke
5. 순수 계산/분기 로직만인가? → 단위 테스트

선택 후 `test_strategy_decision_template.md`를 작성하고 개발자 승인을 받는다.
