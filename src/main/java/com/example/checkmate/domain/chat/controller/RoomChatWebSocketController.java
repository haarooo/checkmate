package com.example.checkmate.domain.chat.controller;

import com.example.checkmate.domain.chat.dto.ChatMessageRequest;
import com.example.checkmate.domain.chat.dto.ChatMessageResponse;
import com.example.checkmate.domain.chat.service.ChatService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.security.Principal;

@Controller
@RequiredArgsConstructor
public class RoomChatWebSocketController {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * 방 채팅 메시지 전송 endpoint.
     * 클라이언트 전송 destination:
     * - /app/rooms/{roomId}/messages
     * 서버 broadcast destination:
     * - /topic/rooms/{roomId}/messages
     *
     * 처리 흐름:
     * 1. STOMP CONNECT 단계에서 등록된 Principal에서 email 추출
     * 2. ChatService에서 방 멤버 검증
     * 3. 메시지 DB 저장
     * 4. 해당 방 topic을 구독 중인 클라이언트에게 broadcast
     */
    @MessageMapping("/rooms/{roomId}/messages")
    public void sendMessage(
            @DestinationVariable Long roomId,
            @Valid @Payload ChatMessageRequest request,
            Principal principal
    ) {
        if (principal == null || principal.getName() == null || principal.getName().isBlank()) {
            throw new IllegalStateException("인증된 사용자만 채팅 메시지를 전송할 수 있습니다.");
        }

        ChatMessageResponse response = chatService.send(
                roomId,
                principal.getName(),
                request
        );

        messagingTemplate.convertAndSend(
                "/topic/rooms/" + roomId + "/messages",
                response
        );
    }
}