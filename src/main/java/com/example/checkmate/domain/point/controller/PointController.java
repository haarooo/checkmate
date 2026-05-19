package com.example.checkmate.domain.point.controller;

import com.example.checkmate.domain.point.dto.PointLedgerResponse;
import com.example.checkmate.domain.point.dto.PointWalletResponse;
import com.example.checkmate.domain.point.dto.TestChargeRequest;
import com.example.checkmate.domain.point.service.PointService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/points")
@RequiredArgsConstructor
public class PointController {

    private final PointService pointService;

    @GetMapping("/me")
    public ResponseEntity<PointWalletResponse> getMyWallet(Authentication authentication) {
        return ResponseEntity.ok(pointService.getMyWallet(authentication.getName()));
    }

    @GetMapping("/me/ledgers")
    public ResponseEntity<List<PointLedgerResponse>> getMyLedgers(Authentication authentication) {
        return ResponseEntity.ok(pointService.getMyLedgers(authentication.getName()));
    }

    @PostMapping("/test/charge")
    public ResponseEntity<PointWalletResponse> testCharge(
            Authentication authentication,
            @Valid @RequestBody TestChargeRequest request) {
        return ResponseEntity.ok(pointService.testCharge(authentication.getName(), request.getAmount()));
    }
}