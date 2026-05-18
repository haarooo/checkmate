package com.example.checkmate.domain.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class UserLoginResponse {

    // 토큰 타입. 일반적으로 Bearer 사용
    private String tokenType;
    // JWT accessToken
    private String accessToken;
    private Long id;
    private String email;
    private String name;
    private String nickname;
    private String role;
}
