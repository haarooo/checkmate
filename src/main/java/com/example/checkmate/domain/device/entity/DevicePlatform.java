package com.example.checkmate.domain.device.entity;

/**
 * FCM 토큰이 발급된 플랫폼을 구분한다.
 * Firebase는 Android(FCM), iOS(APNS), Web(웹 푸시)별로 발송 방식이 다르므로
 * 플랫폼 정보를 저장해 두면 18-2 발송 단계에서 페이로드를 구분할 수 있다.
 */
public enum DevicePlatform {
    ANDROID, IOS, WEB
}
