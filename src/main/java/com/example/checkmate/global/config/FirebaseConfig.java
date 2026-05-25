package com.example.checkmate.global.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;

@Slf4j
@Configuration
public class FirebaseConfig {

    /**
     * Spring Boot가 시작될 때 Firebase Admin SDK를 초기화한다.
     *
     * GOOGLE_APPLICATION_CREDENTIALS 환경변수에 service account JSON 경로를 등록해두면,
     * GoogleCredentials.getApplicationDefault()가 그 파일을 자동으로 읽는다.
     *
     * FirebaseApp은 한 애플리케이션 안에서 중복 초기화하면 예외가 날 수 있으므로,
     * 이미 초기화된 앱이 있는지 먼저 확인한다.
     */
    @PostConstruct
    public void initializeFirebase() {
        if (!FirebaseApp.getApps().isEmpty()) {
            log.info("Firebase Admin SDK already initialized.");
            return;
        }

        try {
            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.getApplicationDefault())
                    .build();

            FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK initialized successfully.");

        } catch (IOException e) {
            throw new IllegalStateException(
                    "Firebase Admin SDK 초기화에 실패했습니다. GOOGLE_APPLICATION_CREDENTIALS 환경변수와 service account JSON 경로를 확인하세요.",
                    e
            );
        }
    }
}
