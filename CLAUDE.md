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

## plan.md , research.md 작성 규칙
- research.md는 40줄 이내
- plan.md는 30줄 이내
- 문서 내용을 그대로 복붙하지 마
- Entity/DTO/Service 전체 코드는 plan.md에 쓰지 마
- 핵심 파일, 핵심 규칙, 제외 범위, 검증 방법만 적어
- 자세한 코드는 구현 단계에서 제안해
