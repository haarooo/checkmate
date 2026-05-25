package com.example.checkmate.domain.fcm.controller;

import com.example.checkmate.domain.fcm.service.FcmService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;


import java.util.Map;

@RestController
@RequestMapping("/api/dev/fcm")
@RequiredArgsConstructor
public class FcmController {

    private final FcmService fcmService;

    /**
     * 18-2 개발 확인용 FCM 발송 API.
     *
     * 목적:
     * - FirebaseConfig가 정상 초기화됐는지 확인한다.
     * - FcmService가 실제 Android FCM token으로 push를 보낼 수 있는지 확인한다.
     *
     * 주의:
     * - 실제 서비스 기능이 아니라 개발 테스트용 API다.
     * - 18-3에서 Notification 이벤트 기반 발송이 붙으면 삭제하거나 dev profile 전용으로 제한한다.
     * - 인증된 사용자만 호출하도록 Authentication을 받는다.
     */
    @PostMapping("/send")
    public ResponseEntity<Map<String, String>> send(
            Authentication authentication,
            @RequestBody FcmTestRequest request) {

        String messageId = fcmService.sendToToken(
                request.getToken(),
                request.getTitle(),
                request.getBody(),
                Map.of(
                        "type", "FCM_TEST",
                        "source", "checkmate-dev"
                )
        );

        return ResponseEntity.ok(Map.of(
                "messageId", messageId,
                "requestedBy", authentication.getName()
        ));
    }

    @Getter
    public static class FcmTestRequest {
        private String token;
        private String title;
        private String body;
    }

}
