# 22_feature_completion_pipeline_research.md

## 파이프라인 확장 목적
- 정산 테스트 하나가 아니라, 어떤 기능이든 AI가 위험도·유형을 판단해 적합한 테스트 레벨을 선택하고 실행하는 "기능 완료 검증 파이프라인" 체계화
- Story 1 핵심 증거: "기능 유형에 맞는 테스트 전략 판단 + 실제 MySQL DB 상태 변화까지 검증"

## 테스트 레벨 기준 (test_strategy_matrix.md 핵심)

| 기능 유형 | 테스트 레벨 |
|-----------|-----------|
| 계산/분기 로직 | 단위 테스트 (Mockito) |
| 상태 변경 / 비즈니스 정책 | 서비스 테스트 (Mockito) |
| DB 저장 / 트랜잭션 / 정합성 | DB 통합 테스트 (SpringBootTest + MySQL) |
| 인증 / 권한 / HTTP 응답 | API 테스트 (MockMvc) |
| FCM / STOMP / 외부 연동 | Mock 테스트 + Smoke 테스트 (수동) |
| 핵심 사용자 플로우 | E2E 테스트 (수동 / 별도 도구) |

## Checkmate 도메인별 기본 테스트 전략

| 도메인 | 전략 | 이유 |
|--------|------|------|
| Settlement | DB 통합 테스트 우선 | 포인트·원장·방·멤버·알림 동시 변경 → 정합성 검증 필수 |
| Proof | API + DB 통합 | 기간/권한/파일 복합, 제출 제한은 DB 조회 의존 |
| Point | DB 통합 | 잔액·원장 정합성이 핵심, 금액 오차 시 직접 피해 |
| Room | 서비스 + API | 상태 전환 흐름 (RECRUITING→READY→IN_PROGRESS→SETTLED) |
| Notification | DB 통합 (FCM 제외) | FCM 발송은 외부 의존, Notification DB 저장까지만 자동 검증 |
| FCM | Smoke 테스트 (수동) | CI 안정성·외부 의존성으로 실제 발송 자동화 제외 |
| STOMP/Chat | 서비스 + Smoke | 메시지 저장·권한은 테스트, WebSocket 연결은 수동 Smoke |
| File Upload | API (파일 메타데이터) | Multipart + 파일 저장 메타데이터 검증 |

## FirebaseConfig 문제 및 해결 방안
- **문제**: `@PostConstruct`에서 `FileInputStream(serviceAccountPath)` 직접 읽음 → 파일 없으면 `IllegalStateException` → `@SpringBootTest` 실패
- **해결**: `@ConditionalOnProperty(name = "firebase.enabled", havingValue = "true", matchIfMissing = true)` 추가
- `src/test/resources/application.properties`에 `firebase.enabled=false` → FirebaseConfig Bean 생성 자체 스킵
- 운영 `application.properties` 변경 없음 (`matchIfMissing=true` → 기존 동작 유지)
- `FcmService`는 `FirebaseMessaging.getInstance()`를 호출 시점 사용 → Bean 생성은 안전

## Notification/FCM 테스트 범위
- **자동 검증 대상**: Notification 엔티티 DB 저장 (notifications 테이블 row 확인)
- **자동 검증 제외**: FCM 실제 발송 및 FCM 이벤트 리스너 동작
- 제외 이유: 외부 Firebase 의존, service account 필요, 실 push 발송 위험, CI 안정성 저하
- `@Transactional` 테스트는 롤백되므로 `AFTER_COMMIT` 리스너 미발동 → FCM 자동 차단

## 테스트 설정 전략
- 설정 파일: `src/test/resources/application.properties` (단일, profile 미사용)
- `@SpringBootTest` + `@Transactional` → 각 테스트 종료 후 롤백
- MySQL `checkmate_test` DB + `spring.jpa.hibernate.ddl-auto=create-drop`
- JWT 최솟값 + `firebase.enabled=false` 포함

## 예상 리스크

| 리스크 | 대응 |
|--------|------|
| CI MySQL 연결 지연 | health-check 옵션 추가 |
| FirebaseConfig `matchIfMissing=true` 누락 시 운영 영향 | 명시적 기재 확인 |
| `@Transactional` 롤백으로 AFTER_COMMIT 미발동 | Notification DB 저장만 검증, FCM verify 제외 |
| DDL create-drop + CI MySQL 권한 | MySQL user에 CREATE/DROP 권한 부여 확인 |
