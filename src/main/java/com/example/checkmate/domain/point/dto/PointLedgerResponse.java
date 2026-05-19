package com.example.checkmate.domain.point.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class PointLedgerResponse {
    private Long id;
    private Long amount;
    private Long balanceAfter;
    private String type;
    private String description;
    private LocalDateTime createdAt;
}