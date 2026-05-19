package com.example.checkmate.domain.room.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@AllArgsConstructor
public class RoomMemberResponse {
    private Long userId;
    private String nickname;
    private String role;
    private String status;
    private LocalDateTime joinedAt;
}