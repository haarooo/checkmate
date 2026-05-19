package com.example.checkmate.domain.user.controller;

import com.example.checkmate.domain.user.dto.UserLoginRequest;
import com.example.checkmate.domain.user.dto.UserLoginResponse;
import com.example.checkmate.domain.user.dto.UserMeResponse;
import com.example.checkmate.domain.user.dto.UserSignupRequest;
import com.example.checkmate.domain.user.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /*
     * 회원가입 API
     * 요청 URL:
     * POST /api/users/signup
     * 요청 Body 예시:
     * {
     *   "email": "test@test.com",
     *   "password": "12345678",
     *   "name": "유환빈",
     *   "nickname": "hwanbin"
     * }
     * 처리 흐름:
     * 1. @Valid로 요청값 검증
     * 2. UserService.signup() 호출
     * 3. 성공하면 201 Created 반환
     */
    @PostMapping("/signup")
    public ResponseEntity<Void> signup(@Valid @RequestBody UserSignupRequest request
    ) {
        userService.signup(request);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    /*
     * 로그인 API
     * 요청 URL:
     * POST /api/users/login
     * 요청 Body 예시:
     * {
     *   "email": "test@test.com",
     *   "password": "12345678"
     * }
     * 처리 흐름:
     * 1. @Valid로 요청값 검증
     * 2. UserService.login() 호출
     * 3. 성공하면 JWT accessToken 반환
     */
    @PostMapping("/login")
    public ResponseEntity<UserLoginResponse> login(@Valid @RequestBody UserLoginRequest request
    ) {
        UserLoginResponse response = userService.login(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UserMeResponse> me(Authentication authentication) {
        UserMeResponse response = userService.getMe(authentication.getName());
        return ResponseEntity.ok(response);
    }
}
