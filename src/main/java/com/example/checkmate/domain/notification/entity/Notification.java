package com.example.checkmate.domain.notification.entity;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "notifications")
public class Notification extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "receiver_id", nullable = false)
    private UserEntity receiver;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id")
    private Room room;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationType type;

    @Column(nullable = false, length = 100)
    private String title;

    @Column(nullable = false, length = 255)
    private String message;

    private LocalDateTime readAt;

    public static Notification create(UserEntity receiver, Room room, NotificationType type,
                                       String title, String message) {
        Notification n = new Notification();
        n.receiver = receiver;
        n.room = room;
        n.type = type;
        n.title = title;
        n.message = message;
        n.readAt = null;
        return n;
    }

    public void markAsRead(LocalDateTime now) {
        if (this.readAt == null) {
            this.readAt = now;
        }
    }
}
