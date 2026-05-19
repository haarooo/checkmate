package com.example.checkmate.domain.point.entity;

import com.example.checkmate.domain.user.entity.UserEntity;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "point_ledgers")
@EntityListeners(AuditingEntityListener.class)
public class PointLedger {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @Column(name = "room_id")
    private Long roomId;

    @Column(nullable = false)
    private Long amount;

    @Column(nullable = false)
    private Long balanceAfter;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LedgerType type;

    private String description;

    @CreatedDate
    @Column(updatable = false)
    private LocalDateTime createdAt;

    public static PointLedger create(
            UserEntity user,
            long amount,
            long balanceAfter,
            LedgerType type,
            String description
    ) {
        PointLedger ledger = new PointLedger();
        ledger.user = user;
        ledger.roomId = null;
        ledger.amount = amount;
        ledger.balanceAfter = balanceAfter;
        ledger.type = type;
        ledger.description = description;
        return ledger;
    }

    public static PointLedger createWithRoom(
            UserEntity user,
            Long roomId,
            long amount,
            long balanceAfter,
            LedgerType type,
            String description
    ) {
        PointLedger ledger = new PointLedger();
        ledger.user = user;
        ledger.roomId = roomId;
        ledger.amount = amount;
        ledger.balanceAfter = balanceAfter;
        ledger.type = type;
        ledger.description = description;
        return ledger;
    }
}