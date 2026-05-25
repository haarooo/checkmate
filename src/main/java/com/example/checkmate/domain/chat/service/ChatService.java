package com.example.checkmate.domain.chat.service;

import com.example.checkmate.domain.chat.dto.ChatMessageRequest;
import com.example.checkmate.domain.chat.dto.ChatMessageResponse;
import com.example.checkmate.domain.chat.entity.RoomMessage;
import com.example.checkmate.domain.chat.repository.RoomMessageRepository;
import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.room.entity.RoomMember;
import com.example.checkmate.domain.room.repository.RoomMemberRepository;
import com.example.checkmate.domain.room.repository.RoomRepository;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.Collections;
import java.util.List;

@Service
@RequiredArgsConstructor
public class ChatService {

    private final RoomMessageRepository roomMessageRepository;
    private final RoomRepository roomRepository;
    private final RoomMemberRepository roomMemberRepository;
    private final UserRepository userRepository;

    /**
     * 특정 방의 최근 채팅 메시지 50개를 조회한다.
     * 권한:
     * - 방 멤버만 조회 가능
     * 정렬:
     * - Repository에서는 createdAt DESC로 최신 50개를 가져온다.
     * - 채팅 화면에서는 오래된 메시지 -> 최신 메시지 순서가 자연스럽기 때문에
     *   Service에서 reverse 후 반환한다.
     */
    @Transactional(readOnly = true)
    public List<ChatMessageResponse> getMessages(Long roomId, String email) {
        Room room = findRoom(roomId);
        UserEntity user = findUser(email);

        validateRoomMember(room, user);

        List<RoomMessage> messages = roomMessageRepository.findTop50ByRoomOrderByCreatedAtDesc(room);

        Collections.reverse(messages);

        return messages.stream()
                .map(ChatMessageResponse::from)
                .toList();
    }

    /**
     * 채팅 메시지를 저장한다.
     *
     * 호출 위치:
     * - WebSocket/STOMP @MessageMapping
     *
     * 권한:
     * - 방 멤버만 전송 가능
     *
     * 중요:
     * - senderId는 클라이언트가 보내지 않는다.
     * - STOMP Principal 또는 HTTP Authentication에서 얻은 email로 UserEntity를 찾아 sender로 저장한다.
     */
    @Transactional
    public ChatMessageResponse send(Long roomId, String email, ChatMessageRequest request) {
        if (request.getContent() == null || request.getContent().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "메시지 내용은 필수입니다.");
        }

        Room room = findRoom(roomId);
        UserEntity sender = findUser(email);

        validateRoomMember(room, sender);

        RoomMessage message = RoomMessage.create(room, sender, request.getContent());
        RoomMessage savedMessage = roomMessageRepository.save(message);

        return ChatMessageResponse.from(savedMessage);
    }

    private Room findRoom(Long roomId) {
        return roomRepository.findById(roomId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "방을 찾을 수 없습니다."));
    }

    private UserEntity findUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "사용자를 찾을 수 없습니다."));
    }

    private void validateRoomMember(Room room, UserEntity user) {
        RoomMember roomMember = roomMemberRepository.findByRoomAndUser(room, user)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.FORBIDDEN, "방 멤버만 채팅을 사용할 수 있습니다."));

        /*
         * 현재 Checkmate에서는 방에 속한 RoomMember면 채팅 가능으로 본다.
         */
    }
}