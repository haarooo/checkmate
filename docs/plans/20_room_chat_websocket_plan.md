# 20_room_chat_websocket_plan.md

## 핵심 파일
신규: domain/chat/{RoomMessage, RoomMessageRepository, ChatService, ChatMessageRequest, ChatMessageResponse}
신규: domain/chat/controller/{RoomChatRestController, RoomChatWebSocketController}
신규: global/websocket/{WebSocketConfig, StompChannelInterceptor}
수정: build.gradle, SecurityConfig
의존성: implementation 'org.springframework.boot:spring-boot-starter-websocket'

## Entity (RoomMessage)
BaseTime 상속. room(FK→rooms, LAZY), sender(FK→users, LAZY), content(TEXT NOT NULL).
@Getter, @NoArgsConstructor(PROTECTED), 정적 팩토리 create().

## DTO
ChatMessageRequest: content(@NotBlank).
ChatMessageResponse: id, roomId, senderId, senderNickname, content, createdAt. 정적 from() 팩토리.

## REST API
RoomChatRestController — GET /api/rooms/{roomId}/messages: 방 멤버만(비멤버 403, 없는 방 404).
DB createdAt DESC 50건 → Service에서 Collections.reverse() → ASC(오래된 순) 반환.

## WebSocket/STOMP 설계
WebSocketConfig: /ws endpoint(no SockJS), /topic broker, /app prefix, CORS allowedOriginPatterns 기존과 동일.
StompChannelInterceptor (CONNECT):
  ① Authorization 헤더에서 "Bearer " 제거 후 token 추출
  ② JwtTokenProvider.validateToken(token) 실패 → MessageDeliveryException throw (연결 거부)
  ③ JwtTokenProvider.getEmail(token)으로 email 추출 → UsernamePasswordAuthenticationToken 생성
  ④ StompHeaderAccessor.setUser(authentication) 등록
  ⑤ 테스트: @MessageMapping 진입 후 log.info("principal={}", principal.getName()) 확인 필수
RoomChatWebSocketController: @MessageMapping("/rooms/{roomId}/messages"), @DestinationVariable Long roomId, Principal principal 수신
  → ChatService.send(roomId, principal.getName(), request) → SimpMessagingTemplate.convertAndSend("/topic/rooms/{roomId}/messages", response)

## SecurityConfig 수정
/ws/** permitAll 추가 (HTTP 핸드셰이크 허용). STOMP 인증은 StompChannelInterceptor 전담.

## 권한 검증 흐름
CONNECT: JWT 검증 + Principal 등록.
SEND: principal.getName()(email) → UserEntity 조회 → RoomMemberRepository.findByRoomAndUser() → 비멤버 throw → 저장/broadcast 없음.
REST GET: Authentication.getName() 동일 경로.
WebSocket 권한 실패: HTTP 403 없음, 예외 throw → ERROR 프레임. 저장/발송 없음.

## 테스트 순서
① build 성공
② GET /api/rooms/{roomId}/messages → 방 멤버 200 빈 배열 / 비멤버 403
③ 잘못된 token CONNECT → ERROR 프레임(연결 거부) 확인
④ 정상 token CONNECT → 성공, principal.getName() 로그 email 확인
⑤ 방 멤버 SEND → DB room_messages 저장 + /topic/.../messages broadcast 수신 확인
⑥ 비멤버 SEND → 저장/발송 없음 확인

## 구현 순서
① build.gradle → ② RoomMessage+Repository → ③ DTO → ④ WebSocketConfig
→ ⑤ StompChannelInterceptor → ⑥ SecurityConfig → ⑦ ChatService
→ ⑧ RoomChatRestController → ⑨ RoomChatWebSocketController → ⑩ build → ⑪ 테스트

## 단계 분리
20-1: 백엔드 WebSocket/STOMP 구현 (이번 단계).
20-2: Flutter RoomChatScreen 연결 (다음 단계).
