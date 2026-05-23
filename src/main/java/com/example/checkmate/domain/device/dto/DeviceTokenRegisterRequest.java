package com.example.checkmate.domain.device.dto;

import lombok.Getter;

/**
 * FCM 토큰 등록 요청 바디.
 * platform은 "ANDROID" | "IOS" | "WEB" 문자열로 받아 서비스에서 enum 변환한다.
 */
@Getter
public class DeviceTokenRegisterRequest {
    private String token;
    private String platform;
}
