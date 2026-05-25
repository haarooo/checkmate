package com.example.checkmate.domain.chat.controller;

import com.example.checkmate.domain.chat.dto.ChatMessageResponse;
import com.example.checkmate.domain.chat.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms/{roomId}/messages")
@RequiredArgsConstructor
public class RoomChatRestController {

    private final ChatService chatService;

    /**
     * 특정 방의 최근 채팅 메시지 50개를 조회한다.
     * 사용 시점:
     * - Flutter RoomChatScreen 진입 직후
     * 흐름:
     * 1. 클라이언트가 기존 메시지 조회
     * 2. 서버는 최근 50개 메시지를 반환
     * 3. 이후 Flutter가 WebSocket/STOMP를 연결해 새 메시지를 실시간 수신
     * 권한:
     * - 방 멤버만 조회 가능
     * - 비멤버는 ChatService에서 403 처리
     */
    @GetMapping
    public ResponseEntity<List<ChatMessageResponse>> getMessages(
            Authentication authentication,
            @PathVariable Long roomId
    ) {
        return ResponseEntity.ok(
                chatService.getMessages(roomId, authentication.getName())
        );
    }
}