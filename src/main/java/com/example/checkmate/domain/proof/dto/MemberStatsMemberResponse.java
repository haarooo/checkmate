package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class MemberStatsMemberResponse {
    private Long userId;
    private String nickname;
    private String role;
    private LocalDateTime joinedAt;
    private long submittedCount;
    private long confirmedCount;
    private int totalRequiredProofCount;
    private int requiredSuccessCount;
    private long remainingRequiredCount;
    private double proofRate;
    private String expectedResult;
}
