package com.example.checkmate.domain.activity.service;

import com.example.checkmate.domain.activity.dto.RoomActivityResponse;
import com.example.checkmate.domain.activity.entity.ActivityType;
import com.example.checkmate.domain.activity.entity.RoomActivity;
import com.example.checkmate.domain.activity.repository.RoomActivityRepository;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RoomActivityService {

    private final RoomActivityRepository roomActivityRepository;
    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;

    public void record(Room room, UserEntity actor, ActivityType type) {
        String message = buildMessage(type, actor);
        roomActivityRepository.save(RoomActivity.create(room, actor, type, message));
    }

    @Transactional(readOnly = true)
    public List<RoomActivityResponse> getActivities(String email, Long roomId) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));
        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
        roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버가 아닙니다."));
        return roomActivityRepository.findTop50ByRoomOrderByCreatedAtDesc(room).stream()
                .map(RoomActivityResponse::from)
                .toList();
    }

    private String buildMessage(ActivityType type, UserEntity actor) {
        return switch (type) {
            case MEMBER_JOINED   -> actorNickname(actor) + "님이 방에 참여했어요.";
            case MEMBER_STAKED   -> actorNickname(actor) + "님이 예치금을 납부했어요.";
            case ROOM_READY      -> "모든 멤버가 예치금을 납부했어요. 방장이 미션을 시작할 수 있어요.";
            case ROOM_STARTED    -> actorNickname(actor) + "님이 미션을 시작했어요. 미션은 내일부터 진행돼요.";
            case PROOF_SUBMITTED -> actorNickname(actor) + "님이 인증을 제출했어요.";
            case PROOF_CONFIRMED -> actorNickname(actor) + "님이 인증을 확인했어요.";
            case ROOM_SETTLED    -> "미션이 정산 완료됐어요.";
        };
    }

    private String actorNickname(UserEntity actor) {
        if (actor == null) {
            throw new IllegalArgumentException("actor is required for this activity type.");
        }
        return actor.getNickname();
    }
}
