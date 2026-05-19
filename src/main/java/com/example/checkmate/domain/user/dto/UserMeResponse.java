package com.example.checkmate.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserMeResponse {
    private Long id;
    private String email;
    private String name;
    private String nickname;
    private String role;
}
