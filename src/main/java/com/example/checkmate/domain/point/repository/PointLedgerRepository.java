package com.example.checkmate.domain.point.repository;

import com.example.checkmate.domain.point.entity.PointLedger;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PointLedgerRepository extends JpaRepository<PointLedger, Long> {
    List<PointLedger> findByUserOrderByCreatedAtDesc(UserEntity user);
}