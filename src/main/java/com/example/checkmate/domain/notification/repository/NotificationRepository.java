package com.example.checkmate.domain.notification.repository;

import com.example.checkmate.domain.notification.entity.Notification;
import com.example.checkmate.domain.user.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findTop50ByReceiverOrderByCreatedAtDesc(UserEntity receiver);

    long countByReceiverAndReadAtIsNull(UserEntity receiver);

    @Modifying
    @Query("update Notification n set n.readAt = :readAt " +
           "where n.receiver = :receiver and n.readAt is null")
    int markAllAsRead(@Param("receiver") UserEntity receiver,
                      @Param("readAt") LocalDateTime readAt);
}
