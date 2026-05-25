package com.example.checkmate.domain.notification.event;

import com.example.checkmate.domain.device.entity.DeviceToken;
import com.example.checkmate.domain.device.service.DeviceTokenService;
import com.example.checkmate.domain.fcm.service.FcmService;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class NotificationFcmEventListener {

    private final UserRepository userRepository;
    private final DeviceTokenService deviceTokenService;
    private final FcmService fcmService;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void handle(NotificationFcmEvent event) {
        log.info(
                "[NotificationFcmEventListener] FCM 발송 이벤트 수신. notificationId={}, receiverUserId={}, type={}",
                event.notificationId(),
                event.receiverUserId(),
                event.type()
        );

        UserEntity receiver = userRepository.findById(event.receiverUserId())
                .orElse(null);

        if (receiver == null) {
            log.warn(
                    "[NotificationFcmEventListener] 수신자를 찾을 수 없어 FCM 발송을 스킵합니다. receiverUserId={}",
                    event.receiverUserId()
            );
            return;
        }

        List<DeviceToken> activeTokens = deviceTokenService.findActiveTokens(receiver);

        if (activeTokens.isEmpty()) {
            log.info(
                    "[NotificationFcmEventListener] 활성 device token이 없어 FCM 발송을 스킵합니다. receiverUserId={}",
                    event.receiverUserId()
            );
            return;
        }

        Map<String, String> data = buildDataPayload(event);

        int successCount = 0;
        int failCount = 0;
        int deactivatedCount = 0;

        for (DeviceToken deviceToken : activeTokens) {
            try {
                fcmService.sendToToken(
                        deviceToken.getToken(),
                        event.title(),
                        event.body(),
                        data
                );
                successCount++;

            } catch (Exception e) {
                failCount++;

                if (isInvalidFcmTokenException(e)) {
                    deviceTokenService.deactivateInvalidToken(deviceToken.getToken());
                    deactivatedCount++;

                    log.warn(
                            "[NotificationFcmEventListener] 무효 FCM token 비활성화. notificationId={}, receiverUserId={}, tokenId={}",
                            event.notificationId(),
                            event.receiverUserId(),
                            deviceToken.getId()
                    );
                } else {
                    log.error(
                            "[NotificationFcmEventListener] FCM 발송 실패. notificationId={}, receiverUserId={}, tokenId={}",
                            event.notificationId(),
                            event.receiverUserId(),
                            deviceToken.getId(),
                            e
                    );
                }
            }
        }

        log.info(
                "[NotificationFcmEventListener] FCM 발송 완료. notificationId={}, receiverUserId={}, successCount={}, failCount={}, deactivatedCount={}",
                event.notificationId(),
                event.receiverUserId(),
                successCount,
                failCount,
                deactivatedCount
        );
    }

    private Map<String, String> buildDataPayload(NotificationFcmEvent event) {
        Map<String, String> data = new HashMap<>();

        data.put("notificationId", String.valueOf(event.notificationId()));
        data.put("type", event.type());

        if (event.data() != null && !event.data().isEmpty()) {
            data.putAll(event.data());
        }

        return data;
    }

    /**
     * Firebase가 token 자체를 더 이상 사용할 수 없다고 응답했는지 확인한다.
     *
     * FcmService는 FirebaseMessagingException을 IllegalStateException으로 감싸서 던진다.
     * 그래서 cause 체인을 따라가며 FirebaseMessagingException을 찾아야 한다.
     */
    private boolean isInvalidFcmTokenException(Throwable throwable) {
        FirebaseMessagingException firebaseException = findFirebaseMessagingException(throwable);

        if (firebaseException == null) {
            return false;
        }

        MessagingErrorCode code = firebaseException.getMessagingErrorCode();

        return code == MessagingErrorCode.UNREGISTERED
                || code == MessagingErrorCode.INVALID_ARGUMENT;
    }

    private FirebaseMessagingException findFirebaseMessagingException(Throwable throwable) {
        Throwable current = throwable;

        while (current != null) {
            if (current instanceof FirebaseMessagingException firebaseException) {
                return firebaseException;
            }

            current = current.getCause();
        }

        return null;
    }
}