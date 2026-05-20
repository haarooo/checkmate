package com.example.checkmate.domain.proof.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class ProofSubmitResponse {
    private Long id;
    private Long roomId;
    private Long userId;
    private LocalDate proofDate;
    private String content;
    private String status;
    private LocalDateTime createdAt;
    private String fileUrl;
    private String fileOriginalName;
    private String fileStoredName;
    private Long fileSize;
    private String fileContentType;
}
