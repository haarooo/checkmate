package com.example.checkmate.domain.room.dto;

import lombok.Getter;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Getter
public class RoomDetailEnrichedResponse {
    private final Long roomId;
    private final String title;
    private final String description;
    private final String status;
    private final String inviteCode;
    private final String inviteLinkToken;
    private final Long ownerId;
    private final String ownerNickname;
    private final String myRole;
    private final String myMemberStatus;
    private final String proofFrequencyType;
    private final int requiredProofCount;
    private final int durationDays;
    private final LocalTime deadlineTime;
    private final int targetRate;
    private final long stakePoint;
    private final int maxMembers;
    private final long currentMemberCount;
    private final long potPoint;
    private final LocalDate missionStartDate;
    private final LocalDate missionEndDate;
    private final LocalDateTime createdAt;
    private final List<RoomMemberResponse> members;

    public RoomDetailEnrichedResponse(
            Long roomId, String title, String description, String status,
            String inviteCode, String inviteLinkToken,
            Long ownerId, String ownerNickname,
            String myRole, String myMemberStatus,
            String proofFrequencyType, int requiredProofCount,
            int durationDays, LocalTime deadlineTime,
            int targetRate, long stakePoint, int maxMembers,
            long currentMemberCount, long potPoint,
            LocalDate missionStartDate, LocalDate missionEndDate,
            LocalDateTime createdAt, List<RoomMemberResponse> members
    ) {
        this.roomId = roomId;
        this.title = title;
        this.description = description;
        this.status = status;
        this.inviteCode = inviteCode;
        this.inviteLinkToken = inviteLinkToken;
        this.ownerId = ownerId;
        this.ownerNickname = ownerNickname;
        this.myRole = myRole;
        this.myMemberStatus = myMemberStatus;
        this.proofFrequencyType = proofFrequencyType;
        this.requiredProofCount = requiredProofCount;
        this.durationDays = durationDays;
        this.deadlineTime = deadlineTime;
        this.targetRate = targetRate;
        this.stakePoint = stakePoint;
        this.maxMembers = maxMembers;
        this.currentMemberCount = currentMemberCount;
        this.potPoint = potPoint;
        this.missionStartDate = missionStartDate;
        this.missionEndDate = missionEndDate;
        this.createdAt = createdAt;
        this.members = members;
    }
}
