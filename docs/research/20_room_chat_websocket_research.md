# 20_room_chat_websocket_research.md

## 1. HTTP vs WebSocket
HTTP: 요청-응답-종료, 실시간 불가. WebSocket: HTTP 업그레이드 → 양방향 지속 연결, 실시간 가능.

## 2. WebSocket vs STOMP
WebSocket: raw 메시지, 라우팅 기준 없음. STOMP: 서브프로토콜, CONNECT/SEND/SUBSCRIBE 명령, destination 라우팅, Spring 기본 지원.

## 3. Checkmate에서 채팅이 필요한 이유
방 멤버끼리 인증 격려·미션 조율·팀 소통 → 방 단위 실시간 텍스트 메시지.

## 4. 메시지 저장/조회 구조
RoomMessage: room(FK), sender(FK), content(TEXT), createdAt.
REST 조회: DB createdAt DESC 50건 → Service에서 reverse → ASC(오래된 순) 반환. 채팅 UI 위→아래 시간순 표시.
STOMP: 전송 즉시 DB 저장 + broadcast.

## 5. STOMP 주소 설계
endpoint: /ws / 전송: /app/rooms/{roomId}/messages / 구독: /topic/rooms/{roomId}/messages

## 6. JWT 인증 처리 방식
현재 JwtAuthenticationFilter는 HTTP 전용 → STOMP 프레임 미통과.
채택: StompChannelInterceptor CONNECT 시 처리
  ① CONNECT 헤더 Authorization: Bearer {token} 추출
  ② JwtTokenProvider.validateToken(token) 검증 → 실패 시 MessageDeliveryException throw (연결 거부)
  ③ JwtTokenProvider.getEmail(token)으로 email 추출 → UsernamePasswordAuthenticationToken 생성
  ④ StompHeaderAccessor.setUser(authentication) → STOMP 세션 Principal 등록
  ⑤ @MessageMapping 메서드에서 Principal principal.getName()으로 email 수신
  ⑥ 테스트 로그에 principal.getName()이 로그인 email로 찍히는지 반드시 확인
제외: URL ?token=... (서버 로그 토큰 노출 위험)

## 7. 방 멤버 권한 검증
CONNECT: JWT 검증 + Principal 등록 (사용자 식별만).
SEND: principal.getName() → email → UserEntity 조회 → RoomMemberRepository.findByRoomAndUser() → 비멤버 throw.
REST GET: Authentication.getName() 동일 경로로 멤버 검증 → 비멤버 403.

## 8. WebSocket 권한 실패 처리
WebSocket SEND 실패는 HTTP 403 응답이 없음.
CONNECT 실패: throw → 서버가 ERROR 프레임 전송, 연결 거부.
SEND 비멤버: ChatService에서 예외 throw → 메시지 저장/broadcast 없음, 클라이언트에 ERROR 프레임.

## 9. 컨트롤러 구조
REST와 WebSocket 혼동 방지를 위해 컨트롤러를 분리한다.
- RoomChatRestController: GET /api/rooms/{roomId}/messages (REST 이전 메시지 조회)
- RoomChatWebSocketController: @MessageMapping("/rooms/{roomId}/messages") (STOMP 메시지 전송)

## 10. MVP 범위 / 단계 분리
포함: 텍스트 메시지, DB 저장, 최근 50건 REST 조회(ASC 반환), STOMP 실시간 송수신, 방 멤버 검증.
제외: 이미지/삭제/수정/읽음/타이핑/채팅 푸시/미읽음 수.
20-1: 백엔드 WebSocket/STOMP 구현. 20-2: Flutter RoomChatScreen 연결.

## 11. 예상 위험
build.gradle WebSocket 의존성 없음 → spring-boot-starter-websocket 추가.
SecurityConfig /ws/** HTTP 핸드셰이크 → permitAll 추가 (기존 구조 유지).
WebSocketConfig CORS → 기존 SecurityConfig allowedOriginPatterns 동일 패턴 적용.
Spring Boot 4.0.6(Spring 6 기반) → spring-boot-starter-websocket 호환 OK.
