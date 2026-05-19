package com.example.checkmate.domain.point.entity;

import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Getter
@Entity
@Table(name = "point_wallets")
public class PointWallet extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private UserEntity user;

    @Column(nullable = false)
    private Long balance;

    @Version
    private Long version;

    public static PointWallet create(UserEntity user) {
        PointWallet wallet = new PointWallet();
        wallet.user = user;
        wallet.balance = 0L;
        return wallet;
    }

    public void addBalance(long amount) {
        this.balance += amount;
    }

    public void subtractBalance(long amount) {
        this.balance -= amount;
    }
}