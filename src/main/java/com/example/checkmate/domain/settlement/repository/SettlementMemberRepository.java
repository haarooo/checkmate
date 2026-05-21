package com.example.checkmate.domain.settlement.repository;

import com.example.checkmate.domain.settlement.entity.Settlement;
import com.example.checkmate.domain.settlement.entity.SettlementMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SettlementMemberRepository extends JpaRepository<SettlementMember, Long> {
    List<SettlementMember> findAllBySettlement(Settlement settlement);
}
