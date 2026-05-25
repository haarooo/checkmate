package com.example.checkmate.domain.notification.service;

import com.example.checkmate.domain.notification.dto.NotificationResponse;
import com.example.checkmate.domain.notification.dto.UnreadCountResponse;
import com.example.checkmate.domain.notification.entity.Notification;
import com.example.checkmate.domain.notification.entity.NotificationType;
import com.example.checkmate.domain.notification.event.NotificationFcmEvent;
import com.example.checkmate.domain.notification.repository.NotificationRepository;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    /*
     * Spring 내부 이벤트를 발행하는 객체다.
     * 여기서는 Notification 저장 후
     * "이 알림을 FCM으로도 보내야 한다"는 NotificationFcmEvent를 발행한다.
     * 실제 FCM 발송은 NotificationFcmEventListener가 담당한다.
     */
    private final ApplicationEventPublisher eventPublisher;

    /**
     * Checkmate의 공통 알림 생성 메서드.
     * 호출되는 상황:
     * - ROOM_STARTED
     * - PROOF_SUBMITTED
     * - PROOF_CONFIRMED
     * - ROOM_SETTLED
     *
     * 처리 흐름:
     * 1. 알림 제목 생성
     * 2. 알림 메시지 생성
     * 3. notifications 테이블에 저장
     * 4. 저장된 notificationId를 포함해 FCM 이벤트 발행
     *
     * 왜 @Transactional을 붙이는가?
     * - NotificationFcmEventListener가 AFTER_COMMIT 시점에 실행되려면
     *   이벤트 발행 시점에 트랜잭션이 존재해야 한다.
     * - 이 메서드가 다른 트랜잭션 안에서 호출되면 그 트랜잭션에 참여한다.
     * - 단독으로 호출되어도 트랜잭션을 만든다.
     */
    @Transactional
    public void notify(Room room, UserEntity receiver, NotificationType type, UserEntity actor) {
        if (receiver == null) {
            throw new IllegalArgumentException("receiver is required for notification.");
        }

        String title = buildTitle(type);
        String message = buildMessage(type, room, actor);

        /*
         * 저장된 Notification을 변수로 받는 이유:
         * - FCM data payload에 notificationId를 넣기 위해서다.
         * - 앱에서 푸시를 눌렀을 때 해당 알림 읽음 처리나 이동에 사용할 수 있다.
         */
        Notification notification = notificationRepository.save(
                Notification.create(receiver, room, type, title, message)
        );

        /*
         * FCM에 같이 실어 보낼 부가 데이터.
         * notificationId와 type은 Listener에서 기본으로 넣고,
         * 여기서는 화면 이동에 필요한 roomId, actorId 같은 값만 추가한다.
         */
        Map<String, String> data = buildFcmData(room, actor);

        /*
         * 여기서 FCM을 직접 보내지 않는다.
         * 이유:
         * - FCM은 외부 네트워크 호출이다.
         * - DB 트랜잭션 안에서 직접 발송하면,
         *   나중에 DB가 롤백됐는데 푸시만 가는 문제가 생길 수 있다.
         * 따라서 이벤트만 발행하고,
         * 실제 발송은 AFTER_COMMIT Listener가 처리한다.
         */
        eventPublisher.publishEvent(
                new NotificationFcmEvent(
                        notification.getId(),
                        receiver.getId(),
                        type.name(),
                        title,
                        message,
                        data
                )
        );
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

    /**
     * FCM data payload에 추가로 넣을 화면 이동용 데이터를 만든다.
     * 예:
     * - roomId가 있으면 푸시 클릭 시 방 상세로 이동 가능
     * - actorId가 있으면 누가 발생시킨 알림인지 앱에서 활용 가능
     *
     * notificationId와 type은 Listener에서 공통으로 넣기 때문에
     * 여기서는 이벤트별 부가 정보만 넣는다.
     */
    private Map<String, String> buildFcmData(Room room, UserEntity actor) {
        Map<String, String> data = new HashMap<>();

        if (room != null) {
            data.put("roomId", String.valueOf(room.getId()));
        }

        if (actor != null) {
            data.put("actorId", String.valueOf(actor.getId()));
            data.put("actorNickname", actor.getNickname());
        }

        return data;
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