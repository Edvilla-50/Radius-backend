package com.Radius.backend.Services;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.auth.oauth2.ServiceAccountCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;
import java.nio.file.Files;
import java.nio.file.Paths;

@Service
public class NotificationService {

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping");
            return;
        }

        try {
            String path = "/etc/secrets/firebase-service-account.json";
            File file = new File(path);

            System.out.println(">>> DEBUGGING SECRET FILE <<<");
            System.out.println("File exists: " + file.exists());
            if (file.exists()) {
                System.out.println("File size in bytes: " + file.length());
                // Read content to see if it's actually JSON or broken text
                String content = Files.readString(Paths.get(path)).trim();
                System.out.println("Does file start with '{': " + content.startsWith("{"));
                
                // Inspect inside the parsed credentials
                try (FileInputStream fis = new FileInputStream(file)) {
                    ServiceAccountCredentials sac = (ServiceAccountCredentials) GoogleCredentials.fromStream(fis);
                    System.out.println(">>> KEY FILE PROJECT ID: " + sac.getProjectId());
                    System.out.println(">>> KEY FILE CLIENT EMAIL: " + sac.getClientEmail());
                } catch (Exception credentialError) {
                    System.err.println(">>> ERROR PARSING CREDENTIALS FROM FILE: " + credentialError.getMessage());
                }
            }

            // Forced initialization check using the file
            if (FirebaseApp.getApps().isEmpty() && file.exists()) {
                try (FileInputStream serviceAccount = new FileInputStream(path)) {
                    FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();
                    FirebaseApp.initializeApp(options);
                    System.out.println(">>> Firebase SDK successfully initialized inline! <<<");
                }
            }

            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("FCM send success! Message ID: " + response);

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification via SDK: " + e.getMessage());
            e.printStackTrace();
        }
    }
}