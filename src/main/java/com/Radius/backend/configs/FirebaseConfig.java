package com.Radius.backend.configs;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

   @PostConstruct
public void initialize() {
    try {
        if (FirebaseApp.getApps().isEmpty()) {
            GoogleCredentials credentials = GoogleCredentials
                .fromStream(new FileInputStream("/etc/secrets/firebase-service-account.json"));

            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(credentials)
                .build();

            FirebaseApp.initializeApp(options);
        }
    } catch (Exception e) {
        throw new RuntimeException("Failed to initialize Firebase: " + e.getMessage(), e);
    }
}
}