package com.example.checkmate.domain.proof.controller;

import com.example.checkmate.domain.proof.dto.ProofConfirmResponse;
import com.example.checkmate.domain.proof.service.ProofService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/proofs")
@RequiredArgsConstructor
public class ProofConfirmController {

    private final ProofService proofService;

    @PostMapping("/{proofId}/confirm")
    public ResponseEntity<ProofConfirmResponse> confirmProof(
            Authentication authentication,
            @PathVariable Long proofId) {
        return ResponseEntity.ok(proofService.confirmProof(authentication.getName(), proofId));
    }
}
