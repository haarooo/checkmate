package com.example.checkmate.domain.settlement.entity;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.ZoneId;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "settlements")
public class Settlement extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false, unique = true)
    private Room room;

    @Column(nullable = false)
    private long totalPotPoint;

    @Column(nullable = false)
    private int totalMembers;

    @Column(nullable = false)
    private int successCount;

    @Column(nullable = false)
    private int failedCount;

    @Column(nullable = false)
    private int totalRequiredProofCount;

    @Column(nullable = false)
    private int requiredSuccessCount;

    @Column(nullable = false)
    private long systemFeePoint;

    @Column(nullable = false)
    private long systemBonusPoint;

    @Column(nullable = false)
    private LocalDateTime settledAt;

    public static Settlement create(
            Room room,
            long totalPotPoint,
            int totalMembers,
            int successCount,
            int failedCount,
            int totalRequiredProofCount,
            int requiredSuccessCount,
            long systemFeePoint,
            long systemBonusPoint
    ) {
        Settlement s = new Settlement();
        s.room = room;
        s.totalPotPoint = totalPotPoint;
        s.totalMembers = totalMembers;
        s.successCount = successCount;
        s.failedCount = failedCount;
        s.totalRequiredProofCount = totalRequiredProofCount;
        s.requiredSuccessCount = requiredSuccessCount;
        s.systemFeePoint = systemFeePoint;
        s.systemBonusPoint = systemBonusPoint;
        s.settledAt = LocalDateTime.now(ZoneId.of("Asia/Seoul"));
        return s;
    }
}
