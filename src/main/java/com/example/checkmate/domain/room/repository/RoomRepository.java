package com.example.checkmate.domain.room.repository;

import com.example.checkmate.domain.room.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface RoomRepository extends JpaRepository<Room, Long> {
    boolean existsByInviteCode(String inviteCode);
    Optional<Room> findByInviteCode(String inviteCode);
    boolean existsByInviteLinkToken(String inviteLinkToken);
    Optional<Room> findByInviteLinkToken(String inviteLinkToken);
}