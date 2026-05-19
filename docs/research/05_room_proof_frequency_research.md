# 05_room_proof_frequency_research.md

## 핵심 파일 현황

| 파일 | 현재 상태 | 필요한 변경 |
|------|-----------|-------------|
| `ProofFrequencyType` | 없음 | 신규 enum 생성 (DAILY, WEEKLY) |
| `Room.java` | proofFrequencyType/requiredProofCount 없음 | 필드 2개 + create() 파라미터 추가 |
| `RoomCreateRequest.java` | 7개 필드 | proofFrequencyType(@NotNull), requiredProofCount(@Min(1)) 추가 |
| `RoomService.java` | createRoom() 검증 없음 | WEEKLY 조건 검증 + create() 전달 추가 |
| `RoomInviteResponse.java` | 11개 필드 | proofFrequencyType, requiredProofCount 추가 |
| `RoomSummaryResponse.java` | 9개 필드 | 동일 추가 |
| `RoomDetailResponse.java` | 16개 필드 | 동일 추가 |

## DB 영향
- `rooms` 테이블에 `proof_frequency_type VARCHAR`, `required_proof_count INT` 컬럼 추가
- `02_DB_DESIGN.md`에는 미기재 → 신규 추가 설계
- Hibernate DDL auto가 설정돼 있으면 자동 반영, 아니면 수동 마이그레이션 필요

## 검증 규칙 (RoomService.createRoom)
- WEEKLY이고 `durationDays % 7 != 0` → 400
- WEEKLY이고 `requiredProofCount > 7` → 400
- DAILY는 `requiredProofCount >= 1`이면 허용 (추가 상한 없음)

## proofType과의 구분
- `proofType` → 금지 필드 (01_BUSINESS_RULES.md, 02_DB_DESIGN.md 모두 금지)
- `proofFrequencyType` → 인증 빈도 설정. 별개 개념. 혼동 금지

## 제외 범위
- Proof 제출/확인 구현 금지
- Room Start 구현 금지
- User, Point, Security, JWT, build.gradle 수정 금지
