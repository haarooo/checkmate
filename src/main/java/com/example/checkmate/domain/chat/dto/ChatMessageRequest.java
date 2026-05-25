package com.example.checkmate.domain.chat.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Getter
@NoArgsConstructor
public class ChatMessageRequest {

    /*
     * 채팅 메시지 본문.
     * MVP에서는 텍스트 메시지만 지원한다.
     * 빈 문자열, 공백 문자열은 허용하지 않는다.
     */
    @NotBlank(message = "메시지 내용은 필수입니다.")
    private String content;
}