package com.example.checkmate.domain.device.dto;

import com.example.checkmate.domain.device.entity.DeviceToken;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
public class DeviceTokenResponse {

    private final Long id;
    private final String token;
    private final String platform;
    private final boolean active;
    private final LocalDateTime createdAt;
    private final LocalDateTime updatedAt;

    private DeviceTokenResponse(Long id, String token, String platform,
                                boolean active, LocalDateTime createdAt, LocalDateTime updatedAt) {
        this.id = id;
        this.token = token;
        this.platform = platform;
        this.active = active;
        this.createdAt = createdAt;
        this.updatedAt = updatedAt;
    }

    public static DeviceTokenResponse from(DeviceToken dt) {
        return new DeviceTokenResponse(
                dt.getId(),
                dt.getToken(),
                dt.getPlatform().name(),
                dt.isActive(),
                dt.getCreatedAt(),
                dt.getUpdatedAt()
        );
    }
}
