# 05_room_proof_frequency_plan.md

## 수정 파일 목록 (순서대로)

### 1. ProofFrequencyType.java (신규)
- `domain/room/entity/` 패키지에 생성
- 값: `DAILY`, `WEEKLY`

### 2. Room.java
- `proofFrequencyType` 필드: `@Enumerated(EnumType.STRING)`, `nullable=false`
- `requiredProofCount` 필드: `int`, `nullable=false`
- `create()` 파라미터에 두 필드 추가, factory 내부 대입

### 3. RoomCreateRequest.java
- `proofFrequencyType`: `@NotNull`
- `requiredProofCount`: `@Min(1)`

### 4. RoomService.java — createRoom() 검증 추가
```
WEEKLY && durationDays % 7 != 0  → 400 "주 단위 방은 진행 기간이 7의 배수여야 합니다."
WEEKLY && requiredProofCount > 7 → 400 "주 단위 인증 횟수는 7 이하여야 합니다."
```
- Room.create() 호출에 두 필드 추가 전달

### 5. RoomInviteResponse.java
- `proofFrequencyType` (String), `requiredProofCount` (int) 필드 추가

### 6. RoomSummaryResponse.java
- 동일 두 필드 추가

### 7. RoomDetailResponse.java
- 동일 두 필드 추가

### 8. RoomService.java — 응답 변환부 3곳 수정
- `getRoomByInviteLinkToken()`: RoomInviteResponse 생성자에 두 필드 추가
- `getMyRooms()`: RoomSummaryResponse 생성자에 두 필드 추가
- `toDetailResponse()`: RoomDetailResponse 생성자에 두 필드 추가

## 검증
- DAILY + requiredProofCount=1 방 생성 성공
- WEEKLY + durationDays=7 + requiredProofCount=3 방 생성 성공
- WEEKLY + durationDays=5 → 400 확인
- WEEKLY + requiredProofCount=8 → 400 확인
- 응답 DTO에 proofFrequencyType, requiredProofCount 포함 확인
- 빌드: `./gradlew.bat clean build`

## 제외
- Proof 제출/확인, Start, Settlement, ShareCard 구현 금지
