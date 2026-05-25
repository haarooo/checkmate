package com.example.checkmate.domain.chat.repository;

import com.example.checkmate.domain.chat.entity.RoomMessage;
import com.example.checkmate.domain.room.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RoomMessageRepository extends JpaRepository<RoomMessage, Long> {

    /*
     * 특정 방의 최근 메시지 50개를 최신순으로 조회한다.
     * DB 조회는 DESC가 유리하다.
     * 다만 채팅 화면에서는 보통 오래된 메시지 → 최신 메시지 순서로 보여줘야 하므로
     * Service에서 이 결과를 reverse해서 반환할 예정이다.
     */
    List<RoomMessage> findTop50ByRoomOrderByCreatedAtDesc(Room room);
}