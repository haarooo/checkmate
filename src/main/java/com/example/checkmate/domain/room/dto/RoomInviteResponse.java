package com.example.checkmate.domain.room.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalTime;

@Getter
@AllArgsConstructor
public class RoomInviteResponse {
    private Long roomId;
    private String title;
    private String description;
    private String status;
    private int durationDays;
    private LocalTime deadlineTime;
    private int targetRate;
    private long stakePoint;
    private int maxMembers;
    private long currentMemberCount;
    private boolean joinable;
}