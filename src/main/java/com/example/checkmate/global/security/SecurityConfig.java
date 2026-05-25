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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

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
     * 2. CORS 허용 여부
     * 3. 세션 사용 여부
     * 4. 어떤 API는 비로그인 허용할지
     * 5. 어떤 API는 로그인 필수로 막을지
     * 6. JWT 필터를 어느 위치에 넣을지
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
                 * Flutter Web / 앱 프론트에서 백엔드 API를 호출할 수 있도록 CORS 활성화
                 * 실제 허용 Origin/Method/Header는 corsConfigurationSource()에서 설정한다.
                 */
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

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
                         * CORS preflight 요청 허용
                         * Flutter Web에서 Authorization 헤더나 multipart 요청을 보내기 전에
                         * 브라우저가 OPTIONS 요청을 먼저 보낼 수 있다.
                         */
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        /*
                         * 회원가입, 로그인, Swagger, 업로드 파일 접근은 토큰 없이 접근 가능해야 함
                         */
                        .requestMatchers(
                                "/api/users/signup",
                                "/api/users/login",
                                "/swagger-ui/**",
                                "/v3/api-docs/**",
                                "/error",
                                "/uploads/**",
                                "/ws/**"
                        ).permitAll()

                        /*
                         * 초대 링크 조회는 비로그인 사용자도 접근 가능
                         */
                        .requestMatchers(
                                HttpMethod.GET, "/api/rooms/invite/**"
                        ).permitAll()

                        /*
                         * 위에서 허용하지 않은 나머지 API는 로그인 필요
                         */
                        .anyRequest().authenticated()
                )

                /*
                 * 로그인 인증에 사용할 AuthenticationProvider 등록
                 */
                .authenticationProvider(authenticationProvider())

                /*
                 * JWT 인증 필터를 UsernamePasswordAuthenticationFilter 앞에 배치
                 * Spring Security가 기본 로그인 인증을 처리하기 전에
                 * JWT 토큰을 검사해서 로그인 상태를 만들어야 한다.
                 */
                .addFilterBefore(
                        jwtAuthenticationFilter,
                        UsernamePasswordAuthenticationFilter.class
                )

                .build();
    }

    /*
     * Flutter Web / Android Emulator / 같은 와이파이 실제 기기 접근을 위한 CORS 설정
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();

        /*
         * 개발 환경 허용 Origin
         *
         * Flutter Web:
         * - http://localhost:xxxxx
         * - http://127.0.0.1:xxxxx
         *
         * Android Emulator:
         * - http://10.0.2.2:8080
         *
         * 실제 휴대폰:
         * - http://192.168.x.x:8080
         */
        configuration.setAllowedOriginPatterns(List.of(
                "http://localhost:*",
                "http://127.0.0.1:*",
                "http://10.0.2.2:*",
                "http://192.168.*.*:*"
        ));

        configuration.setAllowedMethods(List.of(
                "GET",
                "POST",
                "PUT",
                "DELETE",
                "PATCH",
                "OPTIONS"
        ));

        /*
         * Authorization 헤더, Content-Type, multipart/form-data 등 허용
         */
        configuration.setAllowedHeaders(List.of("*"));

        /*
         * Flutter에서 응답 헤더의 Authorization을 읽어야 할 때 대비
         */
        configuration.setExposedHeaders(List.of("Authorization"));

        /*
         * 인증 정보를 포함한 요청 허용
         * allowedOriginPatterns를 사용하므로 true 사용 가능
         */
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);

        return source;
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