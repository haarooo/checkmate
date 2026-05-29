package com.example.checkmate.global.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;

import java.io.FileInputStream;
import java.io.IOException;

@Slf4j
@Configuration
@ConditionalOnProperty(
        name = "firebase.enabled",
        havingValue = "true",
        matchIfMissing = true
)
public class FirebaseConfig {

    /**
     * application.properties에 등록한 Firebase service account JSON 경로를 읽는다.
     *
     * 예:
     * firebase.service-account-path=firebase/checkmate-9a60c-firebase-adminsdk-fbsvc-1471f996f2.json
     */
    @Value("${firebase.service-account-path}")
    private String serviceAccountPath;

    /**
     * Spring Boot가 시작될 때 Firebase Admin SDK를 초기화한다.
     *
     * 현재 방식은 GOOGLE_APPLICATION_CREDENTIALS 환경변수 방식이 아니라,
     * application.properties에 적어둔 JSON 파일 경로를 직접 읽는 방식이다.
     */
    @PostConstruct
    public void initializeFirebase() {
        if (!FirebaseApp.getApps().isEmpty()) {
            log.info("Firebase Admin SDK already initialized.");
            return;
        }

        try (FileInputStream serviceAccount = new FileInputStream(serviceAccountPath)) {

            FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

            FirebaseApp.initializeApp(options);
            log.info("Firebase Admin SDK initialized successfully.");

        } catch (IOException e) {
            throw new IllegalStateException(
                    "Firebase Admin SDK 초기화 실패. service account JSON 파일 경로를 확인하세요. 현재 경로 = "
                            + serviceAccountPath,
                    e
            );
        }
    }
}