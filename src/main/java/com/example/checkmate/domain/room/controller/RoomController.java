package com.example.checkmate.domain.room.controller;

import com.example.checkmate.domain.proof.dto.MemberStatsResponse;
import com.example.checkmate.domain.proof.dto.TodayStatusResponse;
import com.example.checkmate.domain.proof.service.MemberStatsService;
import com.example.checkmate.domain.proof.service.TodayStatusService;
import com.example.checkmate.domain.room.dto.JoinRoomRequest;
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
    private final TodayStatusService todayStatusService;
    private final MemberStatsService memberStatsService;

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

    @GetMapping("/invite/{inviteLinkToken}")
    public ResponseEntity<RoomInviteResponse> getRoomByInviteLinkToken(
            @PathVariable String inviteLinkToken) {
        return ResponseEntity.ok(roomService.getRoomByInviteLinkToken(inviteLinkToken));
    }

    @PostMapping("/{roomId}/join")
    public ResponseEntity<RoomDetailResponse> joinRoom(
            Authentication authentication,
            @PathVariable Long roomId,
            @Valid @RequestBody JoinRoomRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(roomService.joinRoom(authentication.getName(), roomId, request));
    }

    @PostMapping("/{roomId}/stake")
    public ResponseEntity<RoomDetailResponse> stakeRoom(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(roomService.stakeRoom(authentication.getName(), roomId));
    }

    @PostMapping("/{roomId}/start")
    public ResponseEntity<RoomDetailResponse> startRoom(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(roomService.startRoom(authentication.getName(), roomId));
    }

    @GetMapping("/{roomId}/members")
    public ResponseEntity<List<RoomMemberResponse>> getRoomMembers(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(roomService.getRoomMembers(authentication.getName(), roomId));
    }

    @GetMapping("/{roomId}/today-status")
    public ResponseEntity<TodayStatusResponse> getTodayStatus(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(todayStatusService.getTodayStatus(authentication.getName(), roomId));
    }

    @GetMapping("/{roomId}/members/stats")
    public ResponseEntity<MemberStatsResponse> getMemberStats(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(memberStatsService.getMemberStats(authentication.getName(), roomId));
    }
}