package com.Radius.backend.Services;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.util.Collections;

@Service
public class NotificationService {

    private FirebaseApp firebaseApp;

    private synchronized void initializeFirebase() throws Exception {
        String path = "/etc/secrets/firebase-service-account.json";
        
        // Always verify if the app exists under a clean distinct name
        try {
            firebaseApp = FirebaseApp.getInstance("RadiusFinalApp");
        } catch (IllegalStateException e) {
            System.out.println(">>> Generating explicit OAuth2 Credential bindings... <<<");
            
            FileInputStream serviceAccount = new FileInputStream(path);
            
            // Explicitly scope the credentials to Firebase Messaging permissions
            GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount)
                .createScoped(Collections.singletonList("https://www.googleapis.com/auth/firebase.messaging"));
            
            // Force refresh the token immediately to ensure it authenticates before any call
            credentials.refreshIfExpired();

            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(credentials)
                .build();

            firebaseApp = FirebaseApp.initializeApp(options, "RadiusFinalApp");
        }
    }

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping");
            return;
        }

        try {
            // Force fresh secure auth initialization
            initializeFirebase();

            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            // Send via our bound, pre-refreshed application profile instance
            String response = FirebaseMessaging.getInstance(firebaseApp).send(message);
            System.out.println("FCM send success! Message ID: " + response);

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification via SDK: " + e.getMessage());
            e.printStackTrace();
        }
    }
}