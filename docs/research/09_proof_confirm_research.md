# 09_proof_confirm_research.md

## 분석 대상
POST /api/proofs/{proofId}/confirm — 방 멤버가 타인 인증 확인

## 기존 코드 참조
- ProofRepository: findByIdForUpdate(@Lock PESSIMISTIC_WRITE) 추가 필요
- RoomMemberRepository.findByRoomAndUser() — 멤버 검증 재사용
- UserRepository.findByEmail() — 기존 패턴 동일

## 신규 파일
- entity: ProofConfirmation
- repository: ProofConfirmationRepository
- dto: ProofConfirmResponse

## ProofConfirmation Entity 핵심 설계
- proof_confirmations 테이블: proof(FK), room(FK), confirmer(FK), created_at
- @UniqueConstraint(columnNames = {"proof_id", "confirmer_id"}) — 보조 안전장치

## 동시성 처리
- proofRepository.findByIdForUpdate(proofId) — @Lock(PESSIMISTIC_WRITE)
- existsByProofAndConfirmer 체크 + ProofConfirmation 저장을 같은 트랜잭션에서 직렬화
- UniqueConstraint(proof_id, confirmer_id)는 동시 요청 뚫렸을 때 보조 안전장치

## 검증 순서
1. proofRepository.findByIdForUpdate(proofId) → 404
2. userRepository.findByEmail(email) → 404
3. roomMemberRepository.findByRoomAndUser(proof.getRoom(), user) → 403
4. proof.getUser().getId().equals(user.getId()) → 403 (본인 확인 금지)
5. proofConfirmationRepository.existsByProofAndConfirmer(proof, user) → 409
6. proof.getStatus() != CONFIRMED → proof.confirm() 호출
   이미 CONFIRMED이면 confirm() 생략, confirmedAt 유지
7. ProofConfirmation 저장
8. ProofConfirmResponse 반환 (200)

## Proof.confirm() 메서드
- status = CONFIRMED
- confirmedAt = LocalDateTime.now(ZoneId.of("Asia/Seoul")) (최초 1회, 이미 CONFIRMED면 호출 안 함)

## ProofConfirmResponse 필드
- proofId, confirmerId, confirmedAt, status

## 제외
- Today Status / Stats / Settlement / ShareCard 구현 금지
