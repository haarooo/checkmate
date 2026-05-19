package com.example.checkmate.domain.room.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class RoomSummaryResponse {
    private Long id;
    private String title;
    private String status;
    private int maxMembers;
    private long stakePoint;
    private String inviteCode;
    private long currentMemberCount;
    private String myRole;
}