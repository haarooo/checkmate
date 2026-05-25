package com.example.checkmate.domain.device.service;

import com.example.checkmate.domain.device.dto.DeviceTokenDeactivateRequest;
import com.example.checkmate.domain.device.dto.DeviceTokenRegisterRequest;
import com.example.checkmate.domain.device.dto.DeviceTokenResponse;
import com.example.checkmate.domain.device.entity.DevicePlatform;
import com.example.checkmate.domain.device.entity.DeviceToken;
import com.example.checkmate.domain.device.repository.DeviceTokenRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class DeviceTokenService {

    private final DeviceTokenRepository deviceTokenRepository;
    private final UserRepository userRepository;

    /**
     * FCM 토큰을 등록하거나 갱신한다.
     * 앱 시작 시, 로그인 직후, 또는 Firebase가 토큰을 갱신했을 때 프론트에서 호출한다.
     *
     * 처리 분기:
     * - DB에 없는 token → 신규 저장
     * - 있고 같은 user → 플랫폼 갱신 + active=true (재활성화)
     * - 있고 다른 user → 현재 로그인 사용자로 재할당 (기기 전환 대응)
     *
     * DB UNIQUE 제약으로 같은 token이 두 row에 저장되는 일은 없다.
     * JPA dirty checking으로 reactivate/reassign 후 명시적 save 없이 UPDATE가 처리된다.
     */
    @Transactional
    public DeviceTokenResponse register(String email, DeviceTokenRegisterRequest request) {
        if (request.getToken() == null || request.getToken().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "token은 필수입니다.");
        }
        DevicePlatform platform = parsePlatform(request.getPlatform());
        UserEntity user = findUser(email);

        Optional<DeviceToken> existing = deviceTokenRepository.findByToken(request.getToken());

        DeviceToken deviceToken;
        if (existing.isEmpty()) {
            deviceToken = deviceTokenRepository.save(DeviceToken.create(user, request.getToken(), platform));
        } else {
            DeviceToken dt = existing.get();
            if (dt.getUser().getId().equals(user.getId())) {
                dt.reactivate(platform);
            } else {
                dt.reassign(user, platform);
            }
            deviceToken = dt;
        }

        return DeviceTokenResponse.from(deviceToken);
    }

    /**
     * 로그아웃 시 FCM 토큰을 비활성화한다.
     * row를 삭제하지 않고 active=false로 전환해 발송 대상에서 제외한다.
     * 이후 재로그인 시 register()를 호출하면 active=true로 복구된다.
     *
     * 타인의 token을 비활성화하려 하면 403을 반환한다.
     * 조용히 무시하면 클라이언트가 성공으로 오해할 수 있으므로 명시적 오류를 선택한다.
     */
    @Transactional
    public void deactivate(String email, DeviceTokenDeactivateRequest request) {
        if (request.getToken() == null || request.getToken().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "token은 필수입니다.");
        }
        UserEntity user = findUser(email);

        DeviceToken deviceToken = deviceTokenRepository.findByToken(request.getToken())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "등록되지 않은 토큰입니다."));

        if (!deviceToken.getUser().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "본인의 토큰만 비활성화할 수 있습니다.");
        }

        deviceToken.deactivate();
    }

    /**
     * 특정 사용자의 활성 FCM 토큰 전체를 반환한다.
     * 18-2 FCM 발송 단계에서 호출 예정이며, 이번 단계에서는 Controller로 노출하지 않는다.
     */
    @Transactional(readOnly = true)
    public List<DeviceToken> findActiveTokens(UserEntity user) {
        return deviceTokenRepository.findAllByUserAndActiveTrue(user);
    }

    /**
     * platform 문자열을 enum으로 변환한다.
     * null/blank 또는 ANDROID·IOS·WEB 외 값이면 400을 반환한다.
     */
    private DevicePlatform parsePlatform(String platform) {
        if (platform == null || platform.isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "platform은 필수입니다.");
        }
        try {
            return DevicePlatform.valueOf(platform.toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "지원하지 않는 플랫폼입니다. ANDROID, IOS, WEB 중 하나를 입력해 주세요.");
        }
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void deactivateInvalidToken(String token) {
        if (token == null || token.isBlank()) {
            return;
        }

        int updatedCount = deviceTokenRepository.deactivateByToken(token);

        if (updatedCount == 0) {
            return;
        }
    }
}
