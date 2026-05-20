# 09_proof_confirm_plan.md

## 목표
POST /api/proofs/{proofId}/confirm — 방 멤버가 타인 인증 확인, CONFIRMED 전환

## 신규 파일 (domain/proof/)

### 1. ProofConfirmation.java (Entity)
- proof(ManyToOne), room(ManyToOne), confirmer(ManyToOne UserEntity), created_at
- @UniqueConstraint(columnNames = {"proof_id", "confirmer_id"})
- @Getter, @NoArgsConstructor(PROTECTED), 정적 팩토리 create()

### 2. ProofConfirmationRepository.java
- existsByProofAndConfirmer(Proof, UserEntity)

### 3. ProofConfirmResponse.java (DTO)
- proofId, confirmerId, confirmedAt, status

## 기존 파일 수정

### ProofRepository.java
- findByIdForUpdate(@Lock(PESSIMISTIC_WRITE)) Optional<Proof> 추가

### Proof.java
- confirm(): status=CONFIRMED, confirmedAt=LocalDateTime.now(ZoneId.of("Asia/Seoul"))

### ProofService.java (또는 ProofConfirmService.java)
- confirmProof(String email, Long proofId) @Transactional
- 검증 순서:
  1. findByIdForUpdate(proofId) → 404
  2. findByEmail(email) → 404
  3. findByRoomAndUser(proof.getRoom(), user) → 403
  4. proof.getUser().getId().equals(user.getId()) → 403
  5. existsByProofAndConfirmer(proof, user) → 409
  6. proof.getStatus() != CONFIRMED → proof.confirm()
  7. ProofConfirmation 저장
  8. ProofConfirmResponse 반환

### ProofController.java
- POST /api/proofs/{proofId}/confirm 엔드포인트 추가
- @RequestMapping("/api/rooms") 유지, confirm은 별도 매핑 또는 분리 컨트롤러 검토

## 검증
- ./gradlew.bat clean build 성공
- Swagger:
  - 본인 proof 확인 → 403
  - 중복 확인 → 409
  - 정상 확인 → 200, proof.status CONFIRMED 확인
  - 이미 CONFIRMED proof에 새 confirmer 확인 → 200, confirmedAt 유지 확인
