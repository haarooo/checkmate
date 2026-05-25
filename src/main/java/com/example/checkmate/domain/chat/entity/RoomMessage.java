package com.example.checkmate.domain.chat.entity;

import com.example.checkmate.domain.room.entity.Room;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.global.basetime.BaseTime;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "room_messages")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RoomMessage extends BaseTime {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /*
     * 어떤 방의 채팅 메시지인지 나타낸다.
     *
     * 방이 삭제되는 구조는 현재 MVP에 없으므로 cascade/remove는 걸지 않는다.
     * 메시지는 항상 특정 Room에 속한다.
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    /*
     * 메시지를 보낸 사용자.
     * 채팅 전송 시 현재 로그인 사용자를 sender로 저장한다.
     * WebSocket 전송에서도 STOMP Principal에서 email을 꺼내 UserEntity를 찾은 뒤 저장할 예정이다.
     */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "sender_id", nullable = false)
    private UserEntity sender;

    /*
     * 텍스트 메시지 본문.
     * MVP에서는 텍스트 메시지만 지원한다.
     * 이미지, 파일, 삭제/수정, 읽음 처리는 후속 기능으로 제외한다.
     */
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    private RoomMessage(Room room, UserEntity sender, String content) {
        this.room = room;
        this.sender = sender;
        this.content = content;
    }

    public static RoomMessage create(Room room, UserEntity sender, String content) {
        if (room == null) {
            throw new IllegalArgumentException("room is required.");
        }

        if (sender == null) {
            throw new IllegalArgumentException("sender is required.");
        }

        if (content == null || content.isBlank()) {
            throw new IllegalArgumentException("content is required.");
        }

        return new RoomMessage(room, sender, content.trim());
    }
}