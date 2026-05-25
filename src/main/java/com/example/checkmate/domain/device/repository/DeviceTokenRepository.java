package com.example.checkmate.domain.device.repository;

import com.example.checkmate.domain.device.entity.DeviceToken;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DeviceTokenRepository extends JpaRepository<DeviceToken, Long> {

    Optional<DeviceToken> findByToken(String token);

    List<DeviceToken> findAllByUserAndActiveTrue(UserEntity user);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("""
            update DeviceToken dt
               set dt.active = false
             where dt.token = :token
            """)
    int deactivateByToken(@Param("token") String token);
}