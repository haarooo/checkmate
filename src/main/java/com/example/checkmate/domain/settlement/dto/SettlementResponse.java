package com.example.checkmate.domain.settlement.dto;

import com.example.checkmate.domain.settlement.entity.Settlement;
import lombok.Getter;

import java.time.LocalDateTime;
import java.util.List;

@Getter
public class SettlementResponse {
    private final Long settlementId;
    private final Long roomId;
    private final long totalPotPoint;
    private final int totalMembers;
    private final int successCount;
    private final int failedCount;
    private final int totalRequiredProofCount;
    private final int requiredSuccessCount;
    private final long systemFeePoint;
    private final long systemBonusPoint;
    private final LocalDateTime settledAt;
    private final List<SettlementMemberResponse> members;

    public SettlementResponse(Settlement settlement, List<SettlementMemberResponse> members) {
        this.settlementId = settlement.getId();
        this.roomId = settlement.getRoom().getId();
        this.totalPotPoint = settlement.getTotalPotPoint();
        this.totalMembers = settlement.getTotalMembers();
        this.successCount = settlement.getSuccessCount();
        this.failedCount = settlement.getFailedCount();
        this.totalRequiredProofCount = settlement.getTotalRequiredProofCount();
        this.requiredSuccessCount = settlement.getRequiredSuccessCount();
        this.systemFeePoint = settlement.getSystemFeePoint();
        this.systemBonusPoint = settlement.getSystemBonusPoint();
        this.settledAt = settlement.getSettledAt();
        this.members = members;
    }
}
