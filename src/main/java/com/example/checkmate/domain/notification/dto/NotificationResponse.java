package com.example.checkmate.domain.notification.dto;

import com.example.checkmate.domain.notification.entity.Notification;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class NotificationResponse {

    private final Long id;
    private final Long roomId;
    private final String type;
    private final String title;
    private final String message;
    private final boolean read;
    private final LocalDateTime readAt;
    private final LocalDateTime createdAt;

    private NotificationResponse(Long id, Long roomId, String type, String title, String message,
                                   boolean read, LocalDateTime readAt, LocalDateTime createdAt) {
        this.id = id;
        this.roomId = roomId;
        this.type = type;
        this.title = title;
        this.message = message;
        this.read = read;
        this.readAt = readAt;
        this.createdAt = createdAt;
    }

    public static NotificationResponse from(Notification notification) {
        Long roomId = notification.getRoom() != null ? notification.getRoom().getId() : null;
        return new NotificationResponse(
                notification.getId(),
                roomId,
                notification.getType().name(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getReadAt() != null,
                notification.getReadAt(),
                notification.getCreatedAt()
        );
    }
}
