package com.example.checkmate.domain.settlement.repository;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.settlement.entity.Settlement;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface SettlementRepository extends JpaRepository<Settlement, Long> {
    Optional<Settlement> findByRoom(Room room);
}
