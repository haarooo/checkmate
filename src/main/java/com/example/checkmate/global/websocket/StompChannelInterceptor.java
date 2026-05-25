package com.example.checkmate.global.websocket;

import com.example.checkmate.global.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.Message;
import org.springframework.messaging.MessageChannel;
import org.springframework.messaging.MessageDeliveryException;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.ChannelInterceptor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class StompChannelInterceptor implements ChannelInterceptor {

    private final JwtTokenProvider jwtTokenProvider;

    /**
     * 클라이언트가 STOMP CONNECT를 보낼 때 Authorization 헤더를 검사한다.
     * 일반 HTTP 요청은 JwtAuthenticationFilter가 처리하지만,
     * WebSocket/STOMP 프레임은 HTTP 필터를 그대로 타지 않는다.
     * 그래서 STOMP inbound channel에서 직접 JWT를 검증하고,
     * 인증된 사용자를 STOMP 세션 Principal로 등록한다.
     */
    @Override
    public Message<?> preSend(Message<?> message, MessageChannel channel) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(message);

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

        /*
         * 중요:
         * 여기서 꺼내는 값은 기존 JWT의 subject여야 한다.
         * Checkmate JWT는 subject에 email이 들어가는 구조다.
         */
        String email = jwtTokenProvider.getEmail(token);

        if (email == null || email.isBlank()) {
            throw new MessageDeliveryException("JWT에서 사용자 정보를 찾을 수 없습니다.");
        }

        /*
         * STOMP 세션에 Principal 등록.
         * 이후 @MessageMapping 메서드에서
         * Principal principal
         * principal.getName()
         * 으로 email을 꺼낼 수 있다.
         */
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(email, null, List.of());

        accessor.setUser(authentication);
    }
}