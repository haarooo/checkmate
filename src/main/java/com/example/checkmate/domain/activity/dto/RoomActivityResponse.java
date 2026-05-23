package com.example.checkmate.domain.activity.dto;

import com.example.checkmate.domain.activity.entity.RoomActivity;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class RoomActivityResponse {

    private final Long id;
    private final Long roomId;
    private final Long actorId;
    private final String actorNickname;
    private final String type;
    private final String message;
    private final LocalDateTime createdAt;

    private RoomActivityResponse(Long id, Long roomId, Long actorId, String actorNickname,
                                  String type, String message, LocalDateTime createdAt) {
        this.id = id;
        this.roomId = roomId;
        this.actorId = actorId;
        this.actorNickname = actorNickname;
        this.type = type;
        this.message = message;
        this.createdAt = createdAt;
    }

    public static RoomActivityResponse from(RoomActivity activity) {
        Long actorId = activity.getActor() != null ? activity.getActor().getId() : null;
        String actorNickname = activity.getActor() != null ? activity.getActor().getNickname() : null;
        return new RoomActivityResponse(
                activity.getId(),
                activity.getRoom().getId(),
                actorId,
                actorNickname,
                activity.getType().name(),
                activity.getMessage(),
                activity.getCreatedAt()
        );
    }
}
