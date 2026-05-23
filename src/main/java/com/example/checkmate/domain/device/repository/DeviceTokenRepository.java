package com.example.checkmate.domain.device.repository;

import com.example.checkmate.domain.device.entity.DeviceToken;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {

    /**
     * token 문자열로 기존 row를 조회한다.
     * 등록 시 중복 여부 확인과 재할당 판단에 사용한다.
     * token은 DB UNIQUE이므로 결과는 0 또는 1건이다.
     */
    Optional<DeviceToken> findByToken(String token);

    /**
     * 특정 사용자 + token 조합으로 조회한다.
     * 비활성화 시 소유자 확인 용도로 활용 가능하다.
     */
    Optional<DeviceToken> findByUserAndToken(UserEntity user, String token);

    /**
     * 특정 사용자의 활성 token 목록을 조회한다.
     * 18-2 FCM 발송 단계에서 수신 기기를 결정할 때 사용한다.
     * 이번 단계에서는 Controller로 노출하지 않는다.
     */
    List<DeviceToken> findAllByUserAndActiveTrue(UserEntity user);
}
