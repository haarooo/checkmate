package com.example.checkmate.domain.room.repository;

import com.example.checkmate.domain.room.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomRepository extends JpaRepository<Room, Long> {
    boolean existsByInviteCode(String inviteCode);
}