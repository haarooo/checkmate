package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class ProofMemberStatusResponse {
    private Long userId;
    private String nickname;
    private String role;
    private long submittedCount;
    private long confirmedCount;
    private int requiredProofCount;
    private long remainingSubmitCount;
    private long remainingConfirmCount;
    private String status;
}
