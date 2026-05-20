# 08_proof_submit_plan.md

## 목표
POST /api/rooms/{roomId}/proofs — DAILY/WEEKLY 기준별 제출 제한 포함 인증 제출

## 신규 파일 (domain/proof/)

### 1. ProofStatus.java
- SUBMITTED, CONFIRMED

### 2. Proof.java (Entity)
- room(ManyToOne), user(ManyToOne), proofDate, content(nullable)
- fileUrl, fileOriginalName, fileStoredName, fileSize, fileContentType (모두 nullable)
- status(ProofStatus), confirmedAt(nullable)
- 정적 팩토리 create() — 모든 필드 받아 SUBMITTED로 초기화

### 3. ProofRepository.java
- `countByRoomAndUserAndProofDate(Room, UserEntity, LocalDate)` — DAILY
- `countByRoomAndUserAndProofDateBetween(Room, UserEntity, LocalDate, LocalDate)` — WEEKLY

### 4. ProofSubmitResponse.java (DTO)
- id, roomId, userId, proofDate, content, status, createdAt
- fileUrl, fileOriginalName, fileStoredName, fileSize, fileContentType

### 5. ProofService.java
- `submitProof(String email, Long roomId, String content, MultipartFile file)` @Transactional
- 방 조회: roomRepository.findByIdForUpdate(roomId) — 비관적 락으로 동시 제출 직렬화
- proofDate = LocalDate.now(ZoneId.of("Asia/Seoul"))
- 검증 순서:
  1. 404 (방 없음)
  2. 403 (비멤버)
  3. 409 (IN_PROGRESS 아님)
  4. 409 (proofDate < missionStartDate 또는 proofDate > missionEndDate)
  5. 400 (file != null && file.isEmpty())
  6. 400 (content blank + file null)
  7. 409 (제출 수 >= requiredProofCount, DAILY/WEEKLY 분기)
- WEEKLY: weekStart = proofDate.with(DayOfWeek.MONDAY)
          weekEnd   = proofDate.with(DayOfWeek.SUNDAY)
          import java.time.DayOfWeek
- 파일 있으면 fileStorageService.store() → FileUploadResult 필드 매핑
- Proof.create() → save → ProofSubmitResponse 반환

### 6. ProofController.java
- @RequestMapping("/api/rooms")
- @PostMapping(value="/{roomId}/proofs", consumes=MULTIPART_FORM_DATA_VALUE)
- @RequestParam(required=false) content, @RequestPart(required=false) file
- ResponseEntity.status(201).body(...)

## 검증
- `./gradlew.bat clean build` 성공
- Swagger:
  - 빈 파일 전송 → 400 확인
  - content + file 모두 없음 → 400 확인
  - 비멤버 요청 → 403 확인
  - IN_PROGRESS 아닌 방 → 409 확인
  - start 당일 Proof Submit → 미션 기간 전이므로 409 확인
  - 제출 수 초과 → 409 확인
  - 정상 제출 201 → DB에서 missionStartDate를 오늘로 직접 수정한 방에서 확인
    (또는 missionStartDate 당일까지 기다린 후 테스트)
