# CLAUDE.md

Checkmate 프로젝트에서 Claude Code가 지켜야 할 행동 규칙.

## 기본
- 바로 구현하지 말고 문서/코드부터 읽는다.
- 한 번에 한 도메인만 작업한다.
- plan 승인 전 코드를 수정하지 않는다.
- 요청받지 않은 기능/리팩토링 금지.
- 기존 패키지/코드 스타일 우선.
- 충돌 발견 시 수정하지 말고 보고.

## 작업 순서
1. `docs/CURRENT_STATE.md`, `docs/01_BUSINESS_RULES.md` 읽기
2. 필요한 DB/API/순서 문서 읽기
3. 현재 코드 분석
4. `docs/research/{step}_{name}.md` 작성
5. `docs/plans/{step}_{name}.md` 작성
6. 승인 후 구현
7. Swagger 테스트 정리

## 코드 규칙
- Entity: `@Data` 금지, Setter 남발 금지, `@Getter` 기본.
- DTO: record 금지, class + Lombok 사용.
- Controller: 로직 금지, DTO 입출력.
- Service: 비즈니스 로직 담당, 쓰기 작업 `@Transactional`.
- Entity 직접 응답 금지.
- null 반환 금지.

## 금지
- Room에 `proofType` 금지.
- 공개방/실제결제/S3/WebSocket/알림/Redis/Batch 금지.
- PointWallet만 수정하고 PointLedger 누락 금지.
- 중복 인증/중복 확인/중복 정산 허용 금지.

## 검증
- Windows: `./gradlew.bat clean build`
- Git Bash/macOS/Linux: `./gradlew clean build`
- 완료 보고: 변경 파일, API, 규칙 반영, 빌드 결과, Swagger 테스트.

## 폴더 역할 구분

| 폴더 | 사용 시점 | 내용 |
|------|----------|------|
| `docs/research/{step}_{name}.md` | 기능 구현 전 | 코드/문서 분석, 위험도, 접근 방향 |
| `docs/plans/{step}_{name}.md` | 기능 구현 전 | 구현 계획, 핵심 파일, 제외 범위 |
| `docs/ai_test/test_case/{name}_test_case.md` | 기능 구현 후 테스트 작성 전 | 테스트 케이스 목록, 레벨 선택 이유 |
| `docs/ai_test/test_result/{name}_test_result.md` | 테스트 실행 후 | 실행 결과, 실패 분석, 완료 판단 |

**기능 구현 시** → research + plan 작성  
**기존 기능 테스트 시** → test_case 작성 → 코드 작성 → 실행 → test_result 작성

## 기능 완료 파이프라인

AI가 기능 구현을 완료했다고 판단하려면 아래 단계를 모두 수행해야 한다.

1. 관련 문서와 코드를 먼저 확인한다.
2. 기능 유형과 위험도를 분석해 테스트 전략을 제안한다. (`docs/ai_test/test_strategy_matrix.md` 기준)
3. `docs/research/`, `docs/plans/` 작성 후 승인 대기.
4. 사용자 승인 후 구현한다.
5. 구현 후 clean build를 실행한다.
6. `docs/ai_test/test_case/{name}_test_case.md` 작성.
7. 테스트 코드를 작성한다.
8. `./gradlew test`를 실행한다.
9. `docs/ai_test/test_result/{name}_test_result.md` 작성.
10. 실패 시 오류 로그, 원인 분석, 수정 방향을 보고한다.
11. 성공 시 완료 판단.

코드 생성만으로 기능 완료로 보지 않는다.
build와 테스트 결과가 확인되어야 완료로 본다.

## 테스트 결과 보고 규칙

테스트가 실패하면 아래 형식으로 보고한다.

- 실패 테스트명:
- 오류 메시지:
- 예상 값:
- 실제 값:
- 원인 후보:
- 수정 대상 파일:
- 수정 방향:
- 재실행 명령: `./gradlew test`
- 재실행 결과:

테스트가 성공하면 아래 형식으로 보고한다.

- 실행 명령: `./gradlew test`
- 전체 테스트 결과: (N건 성공)
- 통과한 핵심 케이스:
- 남은 리스크:
- 완료 판단:

## plan.md , research.md 작성 규칙
- research.md는 40줄 이내
- plan.md는 30줄 이내
- 문서 내용을 그대로 복붙하지 마
- Entity/DTO/Service 전체 코드는 plan.md에 쓰지 마
- 핵심 파일, 핵심 규칙, 제외 범위, 검증 방법만 적어
- 자세한 코드는 구현 단계에서 제안해
