# 22_feature_completion_pipeline_plan.md

## 목표
기능 유형별 테스트 전략 판단 기준 + 파이프라인 문서 체계화 + Settlement MySQL 통합 테스트 적용

## 추가/수정 파일

| 파일 | 내용 |
|------|------|
| `docs/ai/test_strategy_matrix.md` | 기능 유형 → 테스트 레벨 기준표 + 도메인별 전략 |
| `docs/ai/feature_completion_pipeline.md` | 기능 완료 파이프라인 정의 (AI+개발자 역할 포함) |
| `docs/ai/01_test_automation_story.md` | 포트폴리오 Story 1 |
| `docs/ai/templates/feature_request_analysis_template.md` | 기능 요청 분석 템플릿 |
| `docs/ai/templates/test_strategy_decision_template.md` | 테스트 전략 선택 + 개발자 승인 템플릿 |
| `docs/ai/templates/test_case_template.md` | 테스트 케이스 도출 템플릿 |
| `docs/ai/templates/test_result_report_template.md` | 테스트 결과 보고 템플릿 |
| `docs/ai/templates/feature_completion_report_template.md` | 기능 완료 보고서 템플릿 |
| `docs/ai/examples/settlement_test_strategy_decision.md` | Settlement 전략 선택 예시 |
| `docs/ai/examples/settlement_feature_completion_report.md` | Settlement 완료 보고서 예시 |
| `CLAUDE.md` | 기능 완료 파이프라인 + 테스트 보고 규칙 섹션 추가 |
| `src/main/java/.../global/config/FirebaseConfig.java` | `@ConditionalOnProperty(firebase.enabled, matchIfMissing=true)` 추가 |
| `src/test/resources/application.properties` | MySQL test DB + firebase.enabled=false + JWT 최솟값 |
| `src/test/java/.../settlement/SettlementIntegrationTest.java` | `@SpringBootTest` + `@Transactional` MySQL 통합 테스트 |
| `.github/workflows/backend-ci.yml` | MySQL 8.0 service container + `./gradlew clean test` |

## SettlementIntegrationTest 케이스

| ID | 케이스 | DB 검증 대상 |
|----|--------|-------------|
| TC-S-001 | 전원 성공 | rooms.status=SETTLED, 전원 SUCCESS, rewardPoint=stakePoint+30%, REFUND+SUCCESS_BONUS 원장, Notification 2건 |
| TC-S-002 | 일부 성공 | 성공자 SUCCESS+REFUND+REWARD, 실패자 FAILED+rewardPoint=0+원장 없음 |
| TC-S-003 | 전원 실패 | 전원 FAILED, REFUND 원장, systemFee=potPoint×30% |
| TC-F-001 | 중복 정산 | CONFLICT 예외, settlements 테이블 1건 유지 |
| TC-F-002 | 미션 종료 전 | CONFLICT 예외, settlements 테이블 0건 |

## 테스트 설정
- `src/test/resources/application.properties`: MySQL checkmate_test (root/root) + `create-drop` + `firebase.enabled=false` + JWT 최솟값
- `@SpringBootTest` + `@Transactional` (롤백 → AFTER_COMMIT 리스너 미발동 → FCM 차단)
- profile 미사용, `@ActiveProfiles` 불필요

## Notification/FCM 검증 범위
- **자동 검증**: Notification DB 저장 (notifications 테이블 row count 및 type 확인)
- **제외**: FCM 실제 발송 및 FCM 이벤트 리스너 동작 (외부 의존·CI 안정성·실 push 위험)

## 구현 순서
1. `src/test/resources/application.properties` 생성
2. `FirebaseConfig.java` `@ConditionalOnProperty` 추가
3. `docs/ai/` 문서·템플릿 일체 작성
4. `CLAUDE.md` 파이프라인 섹션 추가
5. `SettlementIntegrationTest.java` 작성
6. `./gradlew clean test` 실행 및 결과 보고
7. `.github/workflows/backend-ci.yml` 추가

## 제외 범위
- H2 사용 금지 / Security 비활성화 방식 금지 / `@ActiveProfiles` 사용 금지
- 운영 코드 대규모 리팩토링 금지 / 정산 정책 변경 금지
- FCM 실제 발송 자동 테스트 금지 / Flutter UI 수정 금지

## 완료 기준
- `./gradlew clean test` 5개 케이스 통과
- docs/ai/ 문서 전체 생성 / CLAUDE.md 업데이트
- FirebaseConfig CI 호환 처리 완료 / backend-ci.yml 추가
