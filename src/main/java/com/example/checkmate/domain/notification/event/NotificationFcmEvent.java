package com.example.checkmate.domain.notification.event;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

public record NotificationFcmEvent(Long notificationId,
                                   Long receiverUserId,
                                   String type,
                                   String title,
                                   String body,
                                   Map<String, String> data) {

    public NotificationFcmEvent {
        if (notificationId == null) {
            throw new IllegalArgumentException("notificationId는 필수입니다.");
        }

        if (receiverUserId == null) {
            throw new IllegalArgumentException("receiverUserId는 필수입니다.");
        }

        if (title == null || title.isBlank()) {
            throw new IllegalArgumentException("title은 필수입니다.");
        }

        if (body == null || body.isBlank()) {
            throw new IllegalArgumentException("body는 필수입니다.");
        }

        if (type == null || type.isBlank()) {
            type = "NOTIFICATION";
        }

        if (data == null) {
            data = Collections.emptyMap();
        } else {
            data = Collections.unmodifiableMap(new HashMap<>(data));
        }
    }


}
