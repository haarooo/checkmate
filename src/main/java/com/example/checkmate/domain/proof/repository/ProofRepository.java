package com.example.checkmate.domain.proof.repository;

import com.example.checkmate.domain.proof.entity.Proof;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;

public interface ProofRepository extends JpaRepository<Proof, Long> {
    long countByRoomAndUserAndProofDate(Room room, UserEntity user, LocalDate proofDate);
    long countByRoomAndUserAndProofDateBetween(Room room, UserEntity user, LocalDate start, LocalDate end);
}
