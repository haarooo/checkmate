package com.example.checkmate.domain.settlement.dto;

import com.example.checkmate.domain.settlement.entity.SettlementMember;
import lombok.Getter;

@Getter
public class SettlementMemberResponse {
    private final Long userId;
    private final String nickname;
    private final String resultStatus;
    private final long submittedCount;
    private final long confirmedCount;
    private final int requiredSuccessCount;
    private final long rewardPoint;
    private final double proofRate;

    public SettlementMemberResponse(SettlementMember sm) {
        this.userId = sm.getUser().getId();
        this.nickname = sm.getUser().getNickname();
        this.resultStatus = sm.getResultStatus().name();
        this.submittedCount = sm.getSubmittedCount();
        this.confirmedCount = sm.getConfirmedCount();
        this.requiredSuccessCount = sm.getRequiredSuccessCount();
        this.rewardPoint = sm.getRewardPoint();
        this.proofRate = sm.getProofRate();
    }
}
