package com.example.checkmate.domain.activity.controller;

import com.example.checkmate.domain.activity.dto.RoomActivityResponse;
import com.example.checkmate.domain.activity.service.RoomActivityService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomActivityController {

    private final RoomActivityService roomActivityService;

    @GetMapping("/{roomId}/activities")
    public ResponseEntity<List<RoomActivityResponse>> getActivities(
            Authentication authentication,
            @PathVariable Long roomId) {
        return ResponseEntity.ok(roomActivityService.getActivities(authentication.getName(), roomId));
    }
}
