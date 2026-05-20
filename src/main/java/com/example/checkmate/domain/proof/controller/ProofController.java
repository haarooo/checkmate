package com.example.checkmate.domain.proof.controller;

import com.example.checkmate.domain.proof.dto.ProofSubmitResponse;
import com.example.checkmate.domain.proof.service.ProofService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class ProofController {

    private final ProofService proofService;

    @PostMapping(value = "/{roomId}/proofs", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ProofSubmitResponse> submitProof(
            Authentication authentication,
            @PathVariable Long roomId,
            @RequestParam(required = false) String content,
            @RequestPart(required = false) MultipartFile file) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(proofService.submitProof(authentication.getName(), roomId, content, file));
    }
}
