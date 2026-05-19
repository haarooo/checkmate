package com.example.checkmate.domain.user.service;

import com.example.checkmate.domain.point.service.PointService;
import com.example.checkmate.domain.user.dto.UserLoginRequest;
import com.example.checkmate.domain.user.dto.UserLoginResponse;
import com.example.checkmate.domain.user.dto.UserMeResponse;
import com.example.checkmate.domain.user.dto.UserSignupRequest;
import com.example.checkmate.domain.user.entity.UserEntity;
import com.example.checkmate.domain.user.repository.UserRepository;
import com.example.checkmate.global.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;


@Service
@Transactional
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final PointService pointService;

    /* 회원가입
     * 1. 이메일 중복 검사
     * 2. 비밀번호 암호화
     * 3. UserEntity 생성
     * 4. DB 저장
     * 실패 케이스:
     * - 이미 가입된 이메일이면 400 Bad Request
     */

    @Transactional
    public void signup(UserSignupRequest request) {

        // 1. 이메일 중복 검사
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "이미 가입된 이메일입니다."
            );
        }
        // 2. 비밀번호 암호화
        String encodedPassword = passwordEncoder.encode(request.getPassword());
        // 3. 회원 Entity 생성
        // 기본 권한은 UserEntity.createUser() 내부에서 ROLE_USER로 설정한다.
        UserEntity user = UserEntity.createUser(
                request.getEmail(),
                encodedPassword,
                request.getName(),
                request.getNickname()
        );
        // 4. 회원 저장
        userRepository.save(user);
        // 5. 포인트 지갑 생성 및 가입 보너스 지급
        pointService.createInitialWallet(user);
    }

    /*
     * 로그인
     * 처리 순서:
     * 1. 이메일/비밀번호 인증 시도
     * 2. 인증 성공 시 사용자 이메일 추출
     * 3. 사용자 권한 추출
     * 4. JWT accessToken 생성
     * 5. 로그인 응답 반환
     * 실패 케이스:
     * - 이메일 또는 비밀번호가 틀리면 401 Unauthorized
     */
    public UserLoginResponse login(UserLoginRequest request) {

        try {
            /*
             * AuthenticationManager가 실제 로그인 인증을 수행한다.
             * 내부 흐름:
             * 1. CustomUserDetailsService.loadUserByUsername(email) 호출
             * 2. DB에서 사용자 조회
             * 3. PasswordEncoder로 입력 비밀번호와 DB 비밀번호 비교
             * 4. 성공하면 Authentication 객체 반환
             */
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            request.getEmail(),
                            request.getPassword()
                    )
            );
            // 인증 성공한 사용자의 email
            String email = authentication.getName();
            /*
             * 로그인 응답에 회원 정보를 같이 내려주기 위해
             * email로 UserEntity를 다시 조회한다.
             * 인증이 성공했다면 원칙적으로 사용자가 존재해야 한다.
             */
            UserEntity user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.UNAUTHORIZED,
                            "인증 정보를 확인할 수 없습니다."
                    ));
            // 사용자 권한
            String role = authentication.getAuthorities()
                    .stream()
                    .map(GrantedAuthority::getAuthority)
                    .findFirst()
                    .orElse("ROLE_USER");
            // JWT accessToken 생성
            String accessToken = jwtTokenProvider.createAccessToken(email, role);
            /*
             * 로그인 응답 반환
             * 주의:
             * password, encodedPassword는 절대 응답에 포함하지 않는다.
             */
            return new UserLoginResponse(
                    "Bearer",
                    accessToken,
                    user.getId(),
                    user.getEmail(),
                    user.getName(),
                    user.getNickname(),
                    role
            );

        } catch (BadCredentialsException e) {
            /*
             * 로그인 실패 처리
             * 보안상 이메일이 틀렸는지, 비밀번호가 틀렸는지 구분하지 않는다.
             */
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "이메일 또는 비밀번호가 올바르지 않습니다."
            );
        }
    }

    @Transactional(readOnly = true)
    public UserMeResponse getMe(String email) {
        UserEntity user = userRepository.findByEmail(email)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "사용자를 찾을 수 없습니다."
                ));
        return new UserMeResponse(
                user.getId(),
                user.getEmail(),
                user.getName(),
                user.getNickname(),
                user.getRole().name()
        );
    }
}
