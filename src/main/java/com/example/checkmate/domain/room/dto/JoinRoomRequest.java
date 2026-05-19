package com.example.checkmate.domain.room.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class JoinRoomRequest {

    @NotBlank
    private String inviteCode;
}
