package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class ProofConfirmResponse {
    private Long proofId;
    private Long confirmerId;
    private LocalDateTime confirmedAt;
    private String status;
}
