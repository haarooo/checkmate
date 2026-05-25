package com.example.checkmate.global.websocket;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;

import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
@RequiredArgsConstructor
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final StompChannelInterceptor stompChannelInterceptor;

    /**
     * 클라이언트가 WebSocket/STOMP 연결을 시작하는 endpoint.
     * Flutter에서는 나중에 아래 주소로 연결한다.
     * - Android Emulator: ws://10.0.2.2:8080/ws
     * - Web: ws://localhost:8080/ws
     * SockJS는 이번 MVP에서 사용하지 않는다.
     * Flutter stomp_dart_client는 일반 WebSocket 연결을 사용할 수 있기 때문이다.
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns(
                        "http://localhost:*",
                        "http://127.0.0.1:*",
                        "http://10.0.2.2:*"
                );
    }

    /**
     * STOMP 메시지 라우팅 규칙.
     * /app:
     * - 클라이언트가 서버로 메시지를 보낼 때 사용
     * - 예: /app/rooms/1/messages
     * /topic:
     * - 서버가 여러 클라이언트에게 broadcast할 때 사용
     * - 예: /topic/rooms/1/messages
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        registry.enableSimpleBroker("/topic");
        registry.setApplicationDestinationPrefixes("/app");
    }

    /**
     * STOMP inbound channel에 인증 interceptor를 연결한다.
     * 역할:
     * - CONNECT 프레임에서 Authorization 헤더 확인
     * - JWT 검증
     * - STOMP 세션에 Principal 저장
     * 이렇게 해야 @MessageMapping 메서드에서 Principal principal을 받을 수 있다.
     */
    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(stompChannelInterceptor);
    }
}