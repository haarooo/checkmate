package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDate;
import java.util.List;

@Getter
@AllArgsConstructor
public class MemberStatsResponse {
    private Long roomId;
    private String roomTitle;
    private String proofFrequencyType;
    private int requiredProofCount;
    private int targetRate;
    private LocalDate missionStartDate;
    private LocalDate missionEndDate;
    private int totalRequiredProofCount;
    private int requiredSuccessCount;
    private List<MemberStatsMemberResponse> members;
}
