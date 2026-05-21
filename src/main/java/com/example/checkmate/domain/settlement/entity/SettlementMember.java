package com.example.checkmate.domain.settlement.entity;

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
@Table(
        name = "settlement_members",
        uniqueConstraints = @UniqueConstraint(columnNames = {"settlement_id", "user_id"})
)
public class SettlementMember extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "settlement_id", nullable = false)
    private Settlement settlement;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private SettlementMemberResult resultStatus;

    @Column(nullable = false)
    private long submittedCount;

    @Column(nullable = false)
    private long confirmedCount;

    @Column(nullable = false)
    private int requiredSuccessCount;

    @Column(nullable = false)
    private long rewardPoint;

    @Column(nullable = false)
    private double proofRate;

    public static SettlementMember create(
            Settlement settlement,
            Room room,
            UserEntity user,
            SettlementMemberResult resultStatus,
            long submittedCount,
            long confirmedCount,
            int requiredSuccessCount,
            long rewardPoint,
            double proofRate
    ) {
        SettlementMember sm = new SettlementMember();
        sm.settlement = settlement;
        sm.room = room;
        sm.user = user;
        sm.resultStatus = resultStatus;
        sm.submittedCount = submittedCount;
        sm.confirmedCount = confirmedCount;
        sm.requiredSuccessCount = requiredSuccessCount;
        sm.rewardPoint = rewardPoint;
        sm.proofRate = proofRate;
        return sm;
    }
}
