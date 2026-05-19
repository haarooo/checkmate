package com.example.checkmate.domain.room.entity;

import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalTime;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "rooms")
public class Room extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private UserEntity owner;

    @Column(nullable = false)
    private String title;

    private String description;

    @Column(nullable = false, unique = true)
    private String inviteCode;

    @Column(nullable = false, unique = true)
    private String inviteLinkToken;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoomStatus status;

    @Column(nullable = false)
    private int durationDays;

    @Column(nullable = false)
    private LocalTime deadlineTime;

    @Column(nullable = false)
    private int targetRate;

    @Column(nullable = false)
    private long stakePoint;

    @Column(nullable = false)
    private int maxMembers;

    @Column(nullable = false)
    private long potPoint;

    private LocalDate missionStartDate;
    private LocalDate missionEndDate;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProofFrequencyType proofFrequencyType;

    @Column(nullable = false)
    private int requiredProofCount;

    public static Room create(
            UserEntity owner,
            String title,
            String description,
            String inviteCode,
            String inviteLinkToken,
            int durationDays,
            LocalTime deadlineTime,
            int targetRate,
            long stakePoint,
            int maxMembers,
            ProofFrequencyType proofFrequencyType,
            int requiredProofCount
    ) {
        Room room = new Room();
        room.owner = owner;
        room.title = title;
        room.description = description;
        room.inviteCode = inviteCode;
        room.inviteLinkToken = inviteLinkToken;
        room.status = RoomStatus.RECRUITING;
        room.durationDays = durationDays;
        room.deadlineTime = deadlineTime;
        room.targetRate = targetRate;
        room.stakePoint = stakePoint;
        room.maxMembers = maxMembers;
        room.potPoint = 0L;
        room.missionStartDate = null;
        room.missionEndDate = null;
        room.proofFrequencyType = proofFrequencyType;
        room.requiredProofCount = requiredProofCount;
        return room;
    }

    public void addPotPoint(long amount) {
        this.potPoint += amount;
    }

    public void markReady() {
        this.status = RoomStatus.READY;
    }
}