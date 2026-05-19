package com.example.checkmate.domain.room.controller;

import com.example.checkmate.domain.room.dto.RoomCreateRequest;
import com.example.checkmate.domain.room.dto.RoomDetailResponse;
import com.example.checkmate.domain.room.dto.RoomInviteResponse;
import com.example.checkmate.domain.room.dto.RoomMemberResponse;
import com.example.checkmate.domain.room.dto.RoomSummaryResponse;
import com.example.checkmate.domain.room.service.RoomService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;

    @PostMapping
    public ResponseEntity<RoomDetailResponse> createRoom(
            Authentication authentication,
            @Valid @RequestBody RoomCreateRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(roomService.createRoom(authentication.getName(), request));
    }

    @GetMapping
    public ResponseEntity<List<RoomSummaryResponse>> getMyRooms(Authentication authentication) {
        return ResponseEntity.ok(roomService.getMyRooms(authentication.getName()));
    }

    @GetMapping("/{roomId}")
    public ResponseEntity<RoomDetailResponse> getRoomDetail(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(roomService.getRoomDetail(authentication.getName(), roomId));
    }

    @GetMapping("/invite/{inviteCode}")
    public ResponseEntity<RoomInviteResponse> getRoomByInviteCode(
            @PathVariable String inviteCode) {
        return ResponseEntity.ok(roomService.getRoomByInviteCode(inviteCode));
    }

    @PostMapping("/{roomId}/join")
    public ResponseEntity<RoomDetailResponse> joinRoom(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(roomService.joinRoom(authentication.getName(), roomId));
    }

    @GetMapping("/{roomId}/members")
    public ResponseEntity<List<RoomMemberResponse>> getRoomMembers(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(roomService.getRoomMembers(authentication.getName(), roomId));
    }
}