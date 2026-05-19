package com.example.checkmate.domain.room.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalTime;

@Getter
@AllArgsConstructor
public class RoomDetailResponse {
    private Long id;
    private String title;
    private String description;
    private String status;
    private String inviteCode;
    private String inviteLinkToken;
    private int durationDays;
    private LocalTime deadlineTime;
    private int targetRate;
    private long stakePoint;
    private int maxMembers;
    private long potPoint;
    private LocalDate missionStartDate;
    private LocalDate missionEndDate;
    private long currentMemberCount;
    private String myRole;
}