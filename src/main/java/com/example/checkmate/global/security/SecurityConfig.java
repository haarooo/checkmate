package com.example.checkmate.global.security;

import com.example.checkmate.domain.user.service.CustomUserDetailsService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CustomUserDetailsService customUserDetailsService;

    /*
     * Spring Security의 핵심 보안 설정
     *
     * 여기서 결정하는 것:
     * 1. CSRF 사용 여부
     * 2. 세션 사용 여부
     * 3. 어떤 API는 비로그인 허용할지
     * 4. 어떤 API는 로그인 필수로 막을지
     * 5. JWT 필터를 어느 위치에 넣을지
     */
    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {

        return http
                /*
                 * REST API + JWT 방식에서는 CSRF를 사용하지 않음
                 * CSRF는 보통 세션/쿠키 기반 로그인에서 문제가 되는 공격 방식.
                 * 우리는 서버 세션이 아니라 Authorization 헤더의 JWT를 사용하므로 비활성화.
                 */
                .csrf(AbstractHttpConfigurer::disable)
                /*
                 * Spring Security 기본 로그인 화면 비활성화
                 * 우리는 HTML 로그인 폼이 아니라
                 * /api/users/login API로 로그인할 것이기 때문.
                 */
                .formLogin(AbstractHttpConfigurer::disable)
                /*
                 * HTTP Basic 인증 비활성화
                 * Basic 인증은 매 요청마다 ID/PW를 헤더에 담는 방식.
                 * 우리는 JWT를 사용할 것이므로 비활성화.
                 */
                .httpBasic(AbstractHttpConfigurer::disable)

                /*
                 * 세션 사용 안 함
                 * JWT 인증은 서버가 로그인 상태를 세션에 저장하지 않고,
                 * 요청마다 토큰을 검증해서 인증 상태를 만든다.
                 */
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)
                )

                /*
                 * URL별 접근 권한 설정
                 */
                .authorizeHttpRequests(auth -> auth

                        /*
                         * 회원가입, 로그인은 토큰 없이 접근 가능해야 함
                         */
                        .requestMatchers(
                                "/api/users/signup",
                                "/api/users/login",
                                "/swagger-ui/**",
                                "/v3/api-docs/**"
                        ).permitAll()

                        /*
                         * 위에서 허용하지 않은 나머지 API는 일단 로그인 필요
                         *
                         * 프로젝트 초반에는 이렇게 막아두는 게 안전함.
                         * 나중에 공개 조회 API가 생기면 permitAll에 추가하면 됨.
                         */
                        .anyRequest().authenticated()
                )

                /*
                 * 로그인 인증에 사용할 AuthenticationProvider 등록
                 */
                .authenticationProvider(authenticationProvider())

                /*
                 * JWT 인증 필터를 UsernamePasswordAuthenticationFilter 앞에 배치
                 * 이유:
                 * Spring Security가 기본 로그인 인증을 처리하기 전에
                 * 우리가 먼저 JWT 토큰을 검사해서 로그인 상태를 만들어야 함.
                 */
                .addFilterBefore(
                        jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class
                )

                .build();
    }

    /*
     * 로그인 인증 처리 담당 Provider
     * 역할:
     * 1. CustomUserDetailsService로 DB에서 사용자 조회
     * 2. PasswordEncoder로 입력 비밀번호와 DB 비밀번호 비교
     */
    @Bean
    public AuthenticationProvider authenticationProvider() {

        DaoAuthenticationProvider provider =
                new DaoAuthenticationProvider(customUserDetailsService);

// 비밀번호 비교에 사용할 암호화 방식
        provider.setPasswordEncoder(passwordEncoder());

        return provider;
    }

    /*
     * AuthenticationManager Bean 등록
     *
     * 나중에 UserService에서 로그인 처리할 때 사용함.
     *
     * authenticationManager.authenticate(...)
     * 이 코드를 통해 이메일/비밀번호 인증을 수행한다.
     */
    @Bean
    public AuthenticationManager authenticationManager(
            AuthenticationConfiguration configuration
    ) throws Exception {
        return configuration.getAuthenticationManager();
    }

    /*
     * 비밀번호 암호화 Bean
     *
     * 회원가입 시:
     * 원문 비밀번호 → BCrypt 암호화 → DB 저장
     *
     * 로그인 시:
     * 입력 비밀번호와 DB의 암호화 비밀번호를 BCrypt 방식으로 비교
     */
    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}
