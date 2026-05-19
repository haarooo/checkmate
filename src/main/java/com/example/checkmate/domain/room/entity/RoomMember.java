package com.example.checkmate.domain.room.entity;

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
@Table(
        name = "room_members",
        uniqueConstraints = @UniqueConstraint(columnNames = {"room_id", "user_id"})
)
public class RoomMember extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoomMemberRole role;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoomMemberStatus status;

    @Column(nullable = false)
    private long stakedPoint;

    @Column(nullable = false)
    private LocalDateTime joinedAt;

    private LocalDateTime stakedAt;

    public static RoomMember createOwner(Room room, UserEntity user) {
        RoomMember member = new RoomMember();
        member.room = room;
        member.user = user;
        member.role = RoomMemberRole.OWNER;
        member.status = RoomMemberStatus.JOINED;
        member.stakedPoint = 0L;
        member.joinedAt = LocalDateTime.now();
        member.stakedAt = null;
        return member;
    }

    public static RoomMember createMember(Room room, UserEntity user) {
        RoomMember member = new RoomMember();
        member.room = room;
        member.user = user;
        member.role = RoomMemberRole.MEMBER;
        member.status = RoomMemberStatus.JOINED;
        member.stakedPoint = 0L;
        member.joinedAt = LocalDateTime.now();
        member.stakedAt = null;
        return member;
    }

    public void stake(long stakedPoint) {
        this.status = RoomMemberStatus.STAKED;
        this.stakedPoint = stakedPoint;
        this.stakedAt = LocalDateTime.now();
    }
}