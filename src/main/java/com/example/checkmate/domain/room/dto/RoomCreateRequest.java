package com.example.checkmate.domain.room.dto;

import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Getter
@NoArgsConstructor
public class RoomCreateRequest {

    @NotBlank(message = "방 제목은 필수입니다.")
    private String title;

    private String description;

    @Min(value = 1, message = "진행 기간은 1일 이상이어야 합니다.")
    private int durationDays;

    @NotNull(message = "마감 시간은 필수입니다.")
    private LocalTime deadlineTime;

    @Min(value = 1, message = "목표 인증률은 1 이상이어야 합니다.")
    @Max(value = 100, message = "목표 인증률은 100 이하여야 합니다.")
    private int targetRate;

    @Min(value = 1, message = "예치 포인트는 1 이상이어야 합니다.")
    private long stakePoint;

    @Min(value = 2, message = "최대 인원은 2명 이상이어야 합니다.")
    private int maxMembers;
}