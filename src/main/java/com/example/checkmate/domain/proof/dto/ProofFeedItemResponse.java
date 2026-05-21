package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class ProofFeedItemResponse {
    private Long proofId;
    private Long roomId;
    private Long userId;
    private String nickname;
    private String content;
    private String fileUrl;
    private String fileOriginalName;
    private String fileContentType;
    private String status;
    private LocalDate proofDate;
    private LocalDateTime createdAt;
    private LocalDateTime confirmedAt;
    private long confirmationCount;
    private long requiredConfirmationCount;
    private boolean canConfirm;
    private boolean isMine;
    private boolean alreadyConfirmedByMe;
}
