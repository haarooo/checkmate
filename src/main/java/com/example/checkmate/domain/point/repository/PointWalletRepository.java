package com.example.checkmate.domain.point.repository;

import com.example.checkmate.domain.point.entity.PointWallet;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface PointWalletRepository extends JpaRepository<PointWallet, Long> {
    Optional<PointWallet> findByUser(UserEntity user);
}