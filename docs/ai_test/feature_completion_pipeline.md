# feature_completion_pipeline.md

AI가 기능 하나를 구현한 뒤 어떤 검증 절차를 거쳐야 "완료"로 볼 수 있는지 정의한다.

> **핵심 원칙**
> AI가 코드를 생성한 시점은 기능 완료가 아니다.
> 기능의 위험도에 맞는 테스트 전략을 선택하고, 테스트 실행 결과까지 확인되어야 기능 완료로 본다.

---

## 파이프라인 단계

```
기능 요청 분석
→ 관련 문서/코드 분석
→ 영향 범위 분석
→ 테스트 전략 선택 (test_strategy_matrix.md 기준, 개발자 승인 필요)
→ 테스트 케이스 도출
→ plan.md 작성
→ 개발자 승인
→ 구현
→ clean build
→ 테스트 코드 작성
→ 테스트 실행 (./gradlew test)
→ 실패 시 오류 원인 분석 및 수정
→ 성공 시 기능 완료 보고서 작성
```

---

## 각 단계 산출물

| 단계 | 산출물 |
|------|--------|
| 기능 요청 분석 | `feature_request_analysis_template.md` 작성 |
| 테스트 전략 선택 | `test_strategy_decision_template.md` 작성 + 개발자 승인 |
| plan 작성 | `docs/plans/{step}_{name}.md` |
| 구현 | 코드 변경 |
| build | 빌드 성공/실패 로그 |
| 테스트 케이스 | `test_case_template.md` 작성 |
| 테스트 실행 | `test_result_report_template.md` 작성 |
| 완료 | `feature_completion_report_template.md` 작성 |

---

## 실패 시 대응 방식

테스트가 실패하면 아래 순서로 분석한다.

1. 어떤 테스트가 실패했는가
2. 예상 값과 실제 값의 차이
3. 비즈니스 로직 오류인가 / 테스트 데이터 오류인가 / 설정 문제인가
4. 수정 대상 파일 특정
5. 수정 후 재실행

분석 결과는 `test_result_report_template.md`에 기록한다.

---

## 성공 시 완료 기준

아래 항목이 모두 충족되어야 기능 완료로 선언한다.

- [ ] clean build 성공
- [ ] 테스트 케이스 작성 완료
- [ ] 테스트 코드 작성 완료
- [ ] `./gradlew test` 성공
- [ ] 실패가 있었다면 원인 분석 및 수정 완료
- [ ] `feature_completion_report_template.md` 작성 완료

---

## 개발자와 AI의 역할 분리

| 역할 | 담당 |
|------|------|
| 테스트 전략 최종 결정 | **개발자** |
| 테스트 케이스 도출 | AI (제안), 개발자 (승인) |
| 테스트 코드 작성 | AI |
| 테스트 실행 | AI (./gradlew test) |
| 실패 원인 분석 | AI (초안), 개발자 (최종 판단) |
| 완료 보고서 작성 | AI |

AI는 기준표를 바탕으로 제안하지만 전략을 독단적으로 결정하지 않는다.
