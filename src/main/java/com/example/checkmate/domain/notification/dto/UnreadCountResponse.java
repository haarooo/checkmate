package com.example.checkmate.domain.notification.dto;

import lombok.Getter;

@Getter
public class UnreadCountResponse {

    private final long unreadCount;

    public UnreadCountResponse(long unreadCount) {
        this.unreadCount = unreadCount;
    }
}
