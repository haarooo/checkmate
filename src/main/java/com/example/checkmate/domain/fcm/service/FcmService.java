package com.example.checkmate.domain.fcm.service;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;
@Slf4j
@Service
public class FcmService {

    /**
     * 단일 FCM token으로 push 알림을 발송한다.
     * token:
     * - 18-1에서 device_tokens 테이블에 저장한 기기 주소다.
     * - Firebase는 이 token을 보고 어떤 기기로 보낼지 판단한다.
     *
     * title/body:
     * - 휴대폰 알림에 표시될 제목과 내용이다.
     *
     * data:
     * - 앱에서 알림 클릭 시 방 상세, 알림 상세 등으로 이동할 때 사용할 부가 정보다.
     * - 예: notificationId, roomId, type
     *
     * 이번 18-2 단계에서는 NotificationService와 자동 연결하지 않고,
     * 서버가 Firebase로 실제 발송할 수 있는지만 검증한다.
     */
    public String sendToToken(String token, String title, String body, Map<String, String> data) {
        validateMessage(token, title, body);

        Message.Builder messageBuilder = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build());

        // data payload는 앱 내부 화면 이동이나 타입 분기에 사용할 수 있다.
        // null이나 빈 Map이면 알림 표시용 notification payload만 전송한다.
        if (data != null && !data.isEmpty()) {
            messageBuilder.putAllData(data);
        }

        try {
            String messageId = FirebaseMessaging.getInstance().send(messageBuilder.build());
            log.info("FCM 발송 성공. messageId={}, token={}", messageId, maskToken(token));
            return messageId;

        } catch (FirebaseMessagingException e) {
            /*
             * 18-2는 Firebase 발송 자체를 검증하는 단계다.
             * 따라서 실패 원인을 바로 확인할 수 있게 예외를 다시 던진다.
             *
             * 18-3에서 Notification 이벤트와 연결할 때는
             * FCM 실패가 원본 Notification 저장 실패로 이어지지 않도록
             * AFTER_COMMIT 이벤트 + 실패 로그 중심으로 분리할 예정이다.
             */
            log.error(
                    "FCM 발송 실패. token={}, errorCode={}, messagingErrorCode={}",
                    maskToken(token),
                    e.getErrorCode(),
                    e.getMessagingErrorCode(),
                    e
            );
            throw new IllegalStateException("FCM 발송에 실패했습니다.", e);
        }
    }

    private void validateMessage(String token, String title, String body) {
        if (token == null || token.isBlank()) {
            throw new IllegalArgumentException("FCM token은 필수입니다.");
        }
        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("FCM title은 필수입니다.");
        }
        if (body == null || body.isBlank()) {
            throw new IllegalArgumentException("FCM body는 필수입니다.");
        }
    }

    /**
     * FCM token은 기기 식별값이므로 로그에 전체를 남기지 않는다.
     * 디버깅에 필요한 앞/뒤 일부만 남긴다.
     */
    private String maskToken(String token) {
        if (token == null || token.length() < 12) {
            return "****";
        }
        return token.substring(0, 6) + "..." + token.substring(token.length() - 6);
    }
}
