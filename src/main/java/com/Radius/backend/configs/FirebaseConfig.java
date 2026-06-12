package com.Radius.backend.configs;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.context.annotation.Configuration;
import jakarta.annotation.PostConstruct;
import java.io.ByteArrayInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initialize() {
        try {
            if (FirebaseApp.getApps().isEmpty()) {
                // 1. Read the secret file as a raw string directly from Render's secret path
                String secretPath = "/etc/secrets/firebase-service-account.json";
                String rawJson = Files.readString(Paths.get(secretPath));

                // 2. Clear out any escaped backslashes Render might have introduced
                String sanitizedJson = rawJson.replace("\\n", "\n");

                // 3. Load credentials safely from the clean stream
                ByteArrayInputStream stream = new ByteArrayInputStream(sanitizedJson.getBytes(StandardCharsets.UTF_8));
                GoogleCredentials credentials = GoogleCredentials.fromStream(stream);

                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(credentials)
                    .build();

                FirebaseApp.initializeApp(options);
                System.out.println(">>> FIREBASE INITIALIZATION SUCCESSFUL WITH SANITIZED CONFIG <<<");
            }
        } catch (Exception e) {
            System.err.println(">>> FIREBASE CRITICAL INITIALIZATION FAILURE <<<");
            e.printStackTrace();
            throw new RuntimeException("Failed to initialize Firebase: " + e.getMessage(), e);
        }
    }
}