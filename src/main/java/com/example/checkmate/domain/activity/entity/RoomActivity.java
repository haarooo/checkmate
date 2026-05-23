package com.example.checkmate.domain.activity.entity;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "room_activities")
public class RoomActivity extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "actor_id")
    private UserEntity actor;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ActivityType type;

    @Column(nullable = false, length = 255)
    private String message;

    public static RoomActivity create(Room room, UserEntity actor, ActivityType type, String message) {
        RoomActivity activity = new RoomActivity();
        activity.room = room;
        activity.actor = actor;
        activity.type = type;
        activity.message = message;
        return activity;
    }
}
