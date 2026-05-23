package com.example.checkmate.domain.notification.service;

import com.example.checkmate.domain.notification.dto.NotificationResponse;
import com.example.checkmate.domain.notification.dto.UnreadCountResponse;
import com.example.checkmate.domain.notification.entity.Notification;
import com.example.checkmate.domain.notification.entity.NotificationType;
import com.example.checkmate.domain.notification.repository.NotificationRepository;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public void notify(Room room, UserEntity receiver, NotificationType type, UserEntity actor) {
        if (receiver == null) {
            throw new IllegalArgumentException("receiver is required for notification.");
        }
        String title = buildTitle(type);
        String message = buildMessage(type, room, actor);
        notificationRepository.save(Notification.create(receiver, room, type, title, message));
    }

    @Transactional(readOnly = true)
    public List<NotificationResponse> getMyNotifications(String email) {
        UserEntity user = findUser(email);
        return notificationRepository.findTop50ByReceiverOrderByCreatedAtDesc(user).stream()
                .map(NotificationResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public UnreadCountResponse getUnreadCount(String email) {
        UserEntity user = findUser(email);
        return new UnreadCountResponse(notificationRepository.countByReceiverAndReadAtIsNull(user));
    }

    @Transactional
    public void markAsRead(String email, Long notificationId) {
        UserEntity user = findUser(email);
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "알림을 찾을 수 없습니다."));
        if (!notification.getReceiver().getId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "본인의 알림만 읽음 처리할 수 있습니다.");
        }
        notification.markAsRead(LocalDateTime.now(ZoneId.of("Asia/Seoul")));
    }

    @Transactional
    public void markAllAsRead(String email) {
        UserEntity user = findUser(email);
        notificationRepository.markAllAsRead(user, LocalDateTime.now(ZoneId.of("Asia/Seoul")));
    }

    private String buildTitle(NotificationType type) {
        return switch (type) {
            case ROOM_STARTED    -> "미션이 시작됐어요";
            case PROOF_SUBMITTED -> "새 인증이 올라왔어요";
            case PROOF_CONFIRMED -> "내 인증이 확인됐어요";
            case ROOM_SETTLED    -> "정산이 완료됐어요";
        };
    }

    private String buildMessage(NotificationType type, Room room, UserEntity actor) {
        return switch (type) {
            case ROOM_STARTED    -> roomTitle(room) + " 미션이 시작됐어요. 내일부터 인증을 진행해요.";
            case PROOF_SUBMITTED -> requireActor(actor) + "님이 인증을 제출했어요. 확인해 주세요.";
            case PROOF_CONFIRMED -> requireActor(actor) + "님이 내 인증을 확인했어요.";
            case ROOM_SETTLED    -> roomTitle(room) + " 정산 결과를 확인해 주세요.";
        };
    }

    private String roomTitle(Room room) {
        if (room == null) {
            throw new IllegalArgumentException("room is required for this notification type.");
        }
        return room.getTitle();
    }

    private String requireActor(UserEntity actor) {
        if (actor == null) {
            throw new IllegalArgumentException("actor is required for this notification type.");
        }
        return actor.getNickname();
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }
}
