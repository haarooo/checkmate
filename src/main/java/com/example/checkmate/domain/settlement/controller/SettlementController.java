package com.example.checkmate.domain.settlement.controller;

import com.example.checkmate.domain.settlement.dto.SettlementResponse;
import com.example.checkmate.domain.settlement.service.SettlementService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Settlement", description = "정산 API")
@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class SettlementController {

    private final SettlementService settlementService;

    @Operation(summary = "방 정산", description = "방 멤버 누구나 정산 실행 가능")
    @PostMapping("/{roomId}/settle")
    public ResponseEntity<SettlementResponse> settle(
            Authentication authentication,
            @PathVariable Long roomId
    ) {
        return ResponseEntity.ok(settlementService.settle(authentication.getName(), roomId));
    }

    @Operation(summary = "정산 결과 조회", description = "방 멤버만 조회 가능, 정산 전 409")
    @GetMapping("/{roomId}/settlement")
    public ResponseEntity<SettlementResponse> getSettlement(
            Authentication authentication,
            @PathVariable Long roomId
    ) {
        return ResponseEntity.ok(settlementService.getSettlement(authentication.getName(), roomId));
    }
}
