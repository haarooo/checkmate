# Feature Completion Report — Settlement 정산 테스트

## 1. 기능명
Settlement 정산 DB 통합 테스트 (`SettlementIntegrationTest`)

## 2. 요청 내용 요약
정산 기능(`POST /api/rooms/{roomId}/settle`)의 반복 Swagger 검증을 테스트 코드 기반 검증으로 전환.
전원 성공 / 일부 성공 / 전원 실패 / 중복 정산 / 미션 종료 전 정산 5개 케이스를 MySQL 실제 DB 상태로 검증.

## 3. 변경 파일

| 파일 | 변경 내용 |
|------|----------|
| `src/test/resources/application.properties` | 테스트용 DB 설정 (checkmate_test, firebase.enabled=false) |
| `src/main/java/.../global/config/FirebaseConfig.java` | `@ConditionalOnProperty(firebase.enabled)` 추가 — 테스트 시 Bean 미생성 |
| `src/test/java/.../settlement/SettlementIntegrationTest.java` | DB 통합 테스트 5건 신규 작성 |

## 4. 구현 내용

- `@SpringBootTest + @Transactional`: 실제 MySQL 스키마 생성(`create-drop`), 각 테스트 후 롤백
- FCM 배제: `firebase.enabled=false` → `FirebaseConfig` Bean 미생성 → `@Transactional` 롤백으로 AFTER_COMMIT 리스너 미실행
- 테스트 데이터: `Room.create()`, `room.start()`, `RoomMember.createOwner/createMember()`, `UserEntity.createUser()`, `Proof.create()` + `proof.confirm()` factory 메서드 전용 사용

## 5. 테스트 케이스

| 구분 | 테스트 내용 | 기대 결과 | 결과 |
|------|------------|----------|------|
| TC-S-001 | 전원 성공 (A, B 각 1건 CONFIRMED) | rewardPoint=13000, REFUND+SUCCESS_BONUS 원장, 알림 2건, SETTLED | PASS |
| TC-S-002 | 일부 성공 (A만 CONFIRMED) | A: 20000P, B: 0P, A원장 2건 / B원장 없음 | PASS |
| TC-S-003 | 전원 실패 (인증 없음) | systemFee=6000, 균등환불 7000씩, REFUND 원장 각 1건 | PASS |
| TC-F-001 | 중복 정산 | 두 번째 settle() → 409 CONFLICT, Settlement 1건 유지 | PASS |
| TC-F-002 | 미션 종료 전 정산 | missionEndDate=내일 → 409 CONFLICT, Settlement 0건 | PASS |

## 6. 실행한 명령어
```bash
./gradlew.bat clean test --tests "com.example.checkmate.domain.settlement.SettlementIntegrationTest"
```

## 7. 테스트 결과

- build 결과: BUILD SUCCESSFUL
- test 결과: 전체 5건 / 성공 5건 / 실패 0건 / 스킵 0건
- 실행 시간: 10.447s (Spring context 포함)

## 9. 남은 리스크

| 항목 | 내용 |
|------|------|
| FCM 실제 발송 | 자동 테스트 배제됨 — 수동 Smoke 테스트 필요 |
| CI 환경 | GitHub Actions MySQL 서비스 컨테이너 연동 별도 확인 필요 |
| 로컬 DB 비밀번호 | test/application.properties: `1234` (로컬 기준), CI: 환경변수 오버라이드 필요 |

## 10. 완료 판단

- [x] build 성공
- [x] 테스트 케이스 작성
- [x] 테스트 코드 작성
- [x] 테스트 실행 성공 (5/5 PASS)
- [x] 문서 업데이트 완료
