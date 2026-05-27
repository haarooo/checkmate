package com.example.checkmate.global.websocket;

import com.example.checkmate.global.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessageDeliveryException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.messaging.support.MessageHeaderAccessor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class StompChannelInterceptor implements ChannelInterceptor {

    public static final String AUTH_EMAIL_KEY = "AUTH_EMAIL";

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor =
                MessageHeaderAccessor.getAccessor(message, StompHeaderAccessor.class);

        if (accessor == null) {
            return message;
        }

        log.info(
                "STOMP preSend. command={}, sessionId={}, user={}",
                accessor.getCommand(),
                accessor.getSessionId(),
                accessor.getUser()
        );

        if (StompCommand.CONNECT.equals(accessor.getCommand())) {
            authenticateConnectFrame(accessor);
        }

        return message;
    }

    private void authenticateConnectFrame(StompHeaderAccessor accessor) {
        String authorizationHeader = accessor.getFirstNativeHeader("Authorization");

        if (authorizationHeader == null || authorizationHeader.isBlank()) {
            throw new MessageDeliveryException("WebSocket 연결에는 Authorization 헤더가 필요합니다.");
        }

        if (!authorizationHeader.startsWith("Bearer ")) {
            throw new MessageDeliveryException("Authorization 헤더 형식이 올바르지 않습니다.");
        }

        String token = authorizationHeader.substring(7);

        if (!jwtTokenProvider.validateToken(token)) {
            throw new MessageDeliveryException("유효하지 않은 WebSocket JWT token입니다.");
        }

        String email = jwtTokenProvider.getEmail(token);

        if (email == null || email.isBlank()) {
            throw new MessageDeliveryException("JWT에서 사용자 정보를 찾을 수 없습니다.");
        }

        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(email, null, List.of());

        accessor.setUser(authentication);

        Map<String, Object> sessionAttributes = accessor.getSessionAttributes();
        if (sessionAttributes != null) {
            sessionAttributes.put(AUTH_EMAIL_KEY, email);
        }

        log.info(
                "STOMP CONNECT 인증 성공. email={}, sessionId={}, user={}",
                email,
                accessor.getSessionId(),
                accessor.getUser()
        );
    }
}