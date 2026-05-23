package com.example.checkmate.domain.device.controller;

import com.example.checkmate.domain.device.dto.DeviceTokenDeactivateRequest;
import com.example.checkmate.domain.device.dto.DeviceTokenRegisterRequest;
import com.example.checkmate.domain.device.dto.DeviceTokenResponse;
import com.example.checkmate.domain.device.service.DeviceTokenService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/device-tokens")
@RequiredArgsConstructor
public class DeviceTokenController {

    private final DeviceTokenService deviceTokenService;

    /**
     * 로그인 직후 또는 Firebase가 token을 갱신했을 때 프론트에서 호출한다.
     * 신규 등록, 재활성화, 다른 계정으로 재할당 모두 200 OK로 통일한다.
     * upsert 성격이므로 201/200 구분은 클라이언트에게 불필요하다.
     */
    @PostMapping
    public ResponseEntity<DeviceTokenResponse> register(
            Authentication authentication,
            @RequestBody DeviceTokenRegisterRequest request) {
        return ResponseEntity.ok(deviceTokenService.register(authentication.getName(), request));
    }

    /**
     * 로그아웃 시 프론트에서 호출해 이 기기로의 FCM 발송을 차단한다.
     * token을 request body로 전달하는 이유: FCM token은 152자 이상이고 콜론(:) 등
     * 특수문자가 포함될 수 있어 path variable의 URL 인코딩 실수 위험을 방지한다.
     */
    @DeleteMapping
    public ResponseEntity<Void> deactivate(
            Authentication authentication,
            @RequestBody DeviceTokenDeactivateRequest request) {
        deviceTokenService.deactivate(authentication.getName(), request);
        return ResponseEntity.noContent().build();
    }
}
