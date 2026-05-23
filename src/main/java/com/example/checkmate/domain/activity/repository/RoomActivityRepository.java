package com.example.checkmate.domain.activity.repository;

import com.example.checkmate.domain.activity.entity.RoomActivity;
import com.example.checkmate.domain.room.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RoomActivityRepository extends JpaRepository<RoomActivity, Long> {
    List<RoomActivity> findTop50ByRoomOrderByCreatedAtDesc(Room room);
}
