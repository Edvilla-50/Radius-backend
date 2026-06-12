package com.Radius.backend.configs;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                String serviceAccount = System.getenv("FIREBASE_SERVICE_ACCOUNT");

                if (serviceAccount == null || serviceAccount.isBlank()) {
                    throw new RuntimeException("FIREBASE_SERVICE_ACCOUNT env var is missing");
                }

                serviceAccount = serviceAccount.trim();
                if (serviceAccount.startsWith("\"") && serviceAccount.endsWith("\"")) {
                    serviceAccount = serviceAccount.substring(1, serviceAccount.length() - 1);
                }
                serviceAccount = serviceAccount.replace("\\n", "\n").replace("\\\"", "\"");
                // Debug — remove after fixing
System.out.println("Service account length: " + serviceAccount.length());
System.out.println("Contains literal newline in key: " + serviceAccount.contains("-----BEGIN PRIVATE KEY-----\n"));
System.out.println("Contains escaped newline in key: " + serviceAccount.contains("-----BEGIN PRIVATE KEY-----\\n"));
                GoogleCredentials credentials = GoogleCredentials
                    .fromStream(new ByteArrayInputStream(
                        serviceAccount.getBytes(StandardCharsets.UTF_8)
                    ));

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