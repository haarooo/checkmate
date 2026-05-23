package com.example.checkmate.domain.device.dto;

import lombok.Getter;

/**
 * 로그아웃 시 비활성화할 FCM 토큰을 request body로 전달받는다.
 * path variable 대신 body를 사용하는 이유: FCM 토큰은 길고 콜론(:) 등 특수문자가 포함될 수 있어
 * URL 인코딩 실수를 방지하기 위해 body 전달 방식을 선택했다.
 */
@Getter
public class DeviceTokenDeactivateRequest {
    private String token;
}
