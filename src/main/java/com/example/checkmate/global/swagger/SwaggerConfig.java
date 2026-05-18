package com.example.checkmate.global.swagger;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class SwaggerConfig {

    /*
     * Swagger/OpenAPI 기본 설정
     * 역할:
     * 1. Swagger 문서 제목/설명/버전 설정
     * 2. JWT Bearer 인증 방식을 Swagger에 등록
     * 3. Swagger UI 상단에 Authorize 버튼 생성
     */
    @Bean
    public OpenAPI openAPI() {

        // Swagger에서 사용할 JWT 인증 스키마 이름
        String jwtSchemeName = "JWT";
        /*
         * SecurityRequirement
         * Swagger 문서 전체에 JWT 인증 방식을 적용한다.
         * 이 설정이 있어야 Swagger UI에서 Authorize 버튼으로 넣은 토큰이
         * API 요청 Header에 자동으로 포함된다.
         */
        SecurityRequirement securityRequirement =
                new SecurityRequirement().addList(jwtSchemeName);

        /*
         * SecurityScheme
         * Authorization: Bearer {token}
         * 형태의 JWT 인증 방식을 정의한다.
         */
        SecurityScheme securityScheme = new SecurityScheme()
                .name(jwtSchemeName)
                .type(SecurityScheme.Type.HTTP)
                .scheme("bearer")
                .bearerFormat("JWT");

        return new OpenAPI()
                .info(new Info()
                        .title("Checkmate API")
                        .description("Checkmate 회원가입/로그인 JWT 인증 API 문서")
                        .version("v1.0.0")
                )
                .addSecurityItem(securityRequirement)
                .components(new Components()
                        .addSecuritySchemes(jwtSchemeName, securityScheme)
                );
    }
}
