package com.example.checkmate.domain.chat.controller;

import com.example.checkmate.domain.chat.dto.ChatMessageRequest;
import com.example.checkmate.domain.chat.dto.ChatMessageResponse;
import com.example.checkmate.domain.chat.service.ChatService;
import com.example.checkmate.global.websocket.StompChannelInterceptor;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.DestinationVariable;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Controller;

import java.security.Principal;
import java.util.Map;

@Slf4j
@Controller
@RequiredArgsConstructor
public class RoomChatWebSocketController {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;

    @MessageMapping("/rooms/{roomId}/messages")
    public void sendMessage(
            @DestinationVariable Long roomId,
            @Valid @Payload ChatMessageRequest request,
            Principal principal,
            SimpMessageHeaderAccessor headerAccessor
    ) {
        String email = resolveEmail(principal, headerAccessor);

        log.info("STOMP 채팅 메시지 수신. roomId={}, email={}", roomId, email);

        ChatMessageResponse response = chatService.send(
                roomId,
                email,
                request
        );

        messagingTemplate.convertAndSend(
                "/topic/rooms/" + roomId + "/messages",
                response
        );
    }

    private String resolveEmail(
            Principal principal,
            SimpMessageHeaderAccessor headerAccessor
    ) {
        if (principal != null && principal.getName() != null && !principal.getName().isBlank()) {
            return principal.getName();
        }

        if (headerAccessor != null) {
            Map<String, Object> sessionAttributes = headerAccessor.getSessionAttributes();

            if (sessionAttributes != null) {
                Object email = sessionAttributes.get(StompChannelInterceptor.AUTH_EMAIL_KEY);

                if (email instanceof String emailValue && !emailValue.isBlank()) {
                    return emailValue;
                }
            }
        }

        throw new IllegalStateException("인증된 사용자만 채팅 메시지를 전송할 수 있습니다.");
    }
}