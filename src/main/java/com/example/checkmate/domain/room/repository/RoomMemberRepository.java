package com.example.checkmate.domain.room.repository;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.entity.RoomMemberStatus;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface RoomMemberRepository extends JpaRepository<RoomMember, Long> {
    List<RoomMember> findAllByUser(UserEntity user);
    List<RoomMember> findAllByRoomOrderByJoinedAtAsc(Room room);
    Optional<RoomMember> findByRoomAndUser(Room room, UserEntity user);
    long countByRoom(Room room);
    long countByRoomAndStatus(Room room, RoomMemberStatus status);
}