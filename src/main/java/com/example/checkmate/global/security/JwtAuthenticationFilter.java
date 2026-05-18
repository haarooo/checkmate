package com.example.checkmate.global.security;

import com.example.checkmate.domain.user.service.CustomUserDetailsService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;


@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter{

    private final JwtTokenProvider jwtTokenProvider;
    private final CustomUserDetailsService customUserDetailsService;

    /*
     * 모든 HTTP 요청마다 한 번씩 실행되는 필터 메서드
     * 역할:
     * 1. 요청 Header에서 JWT 토큰을 꺼낸다.
     * 2. 토큰이 유효한지 검사한다.
     * 3. 토큰에서 email을 꺼낸다.
     * 4. email로 회원 정보를 조회한다.
     * 5. Spring SecurityContext에 인증 정보를 저장한다.
     */
    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain
    ) throws ServletException, IOException {

        // 1. Authorization 헤더에서 Bearer 토큰 추출
        String token = resolveToken(request);

        // 2. 토큰이 존재하고, 유효한 토큰인지 검사
        if (token != null && jwtTokenProvider.validateToken(token)) {

            // 3. JWT에서 로그인 사용자 email 추출
            String email = jwtTokenProvider.getEmail(token);

            // 4. email로 DB에서 사용자 정보 조회
            UserDetails userDetails = customUserDetailsService.loadUserByUsername(email);

            /*
             * 5. Spring Security가 사용할 인증 객체 생성
             *
             * 첫 번째 값: 로그인 사용자 정보
             * 두 번째 값: 비밀번호. JWT 인증에서는 이미 토큰으로 검증했으므로 null
             * 세 번째 값: 사용자 권한 목록
             */
            UsernamePasswordAuthenticationToken authentication =
                    new UsernamePasswordAuthenticationToken(
                            userDetails,
                            null,
                            userDetails.getAuthorities()
                    );

            // 6. 현재 요청 정보(IP, 세션 ID 등)를 인증 객체에 추가
            authentication.setDetails(
                    new WebAuthenticationDetailsSource().buildDetails(request)
            );

            // 7. SecurityContext에 인증 정보 저장
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }

        // 8. 다음 필터로 요청 전달
        filterChain.doFilter(request, response);
    }

    /*
     * Authorization 헤더에서 JWT 토큰만 추출하는 메서드
     *
     * 요청 헤더 예시:
     * Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
     *
     * 여기서 "Bearer "를 제거하고 실제 토큰 문자열만 반환한다.
     */
    private String resolveToken(HttpServletRequest request) {

        // Authorization 헤더 값 조회
        String bearerToken = request.getHeader("Authorization");

        // 헤더가 존재하고 "Bearer "로 시작하면 실제 토큰 부분만 잘라서 반환
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }

        // 토큰이 없으면 null 반환
        return null;
    }
}
