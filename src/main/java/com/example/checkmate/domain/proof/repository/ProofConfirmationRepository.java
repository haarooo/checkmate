package com.example.checkmate.domain.proof.repository;

import com.example.checkmate.domain.proof.entity.Proof;
import com.example.checkmate.domain.proof.entity.ProofConfirmation;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ProofConfirmationRepository extends JpaRepository<ProofConfirmation, Long> {
    boolean existsByProofAndConfirmer(Proof proof, UserEntity confirmer);
    long countByProof(Proof proof);
}
