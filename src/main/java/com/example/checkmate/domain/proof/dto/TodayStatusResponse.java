package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

@Getter
@AllArgsConstructor
public class TodayStatusResponse {
    private Long roomId;
    private String proofFrequencyType;
    private int requiredProofCount;
    private LocalDate periodStart;
    private LocalDate periodEnd;
    private LocalTime deadlineTime;
    private boolean deadlinePassed;
    private ProofMemberStatusResponse myStatus;
    private List<ProofMemberStatusResponse> members;
}
