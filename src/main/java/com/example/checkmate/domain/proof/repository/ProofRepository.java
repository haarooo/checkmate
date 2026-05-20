package com.example.checkmate.domain.proof.repository;

import com.example.checkmate.domain.proof.entity.Proof;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Optional;

public interface ProofRepository extends JpaRepository<Proof, Long> {
    long countByRoomAndUserAndProofDate(Room room, UserEntity user, LocalDate proofDate);
    long countByRoomAndUserAndProofDateBetween(Room room, UserEntity user, LocalDate start, LocalDate end);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT p FROM Proof p WHERE p.id = :id")
    Optional<Proof> findByIdForUpdate(@Param("id") Long id);
}
