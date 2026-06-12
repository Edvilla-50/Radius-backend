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
        String appName = "RadiusCustomAuthApp";
        
        try {
            firebaseApp = FirebaseApp.getInstance(appName);
        } catch (IllegalStateException e) {
            System.out.println(">>> Requesting fresh OAuth2 token explicitly from Google IAM... <<<");
            
            FileInputStream serviceAccount = new FileInputStream(path);
            
            // Explicitly target the scoped Firebase Messaging API endpoint
            GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount)
                .createScoped(Collections.singletonList("https://www.googleapis.com/auth/cloud-platform"));
            
            // Force an immediate server handshake to fetch the token right now
            credentials.refresh();
            System.out.println(">>> Token successfully minted! Expiry: " + credentials.getAccessToken().getExpirationTime() + " <<<");

            FirebaseOptions options = FirebaseOptions.builder()
                .setCredentials(credentials)
                .setProjectId("radius-6ad92") // Explicitly hardcode target project
                .build();

            firebaseApp = FirebaseApp.initializeApp(options, appName);
        }
    }

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping");
            return;
        }

        try {
            initializeFirebase();

            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            String response = FirebaseMessaging.getInstance(firebaseApp).send(message);
            System.out.println("FCM send success! Message ID: " + response);

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification via SDK: " + e.getMessage());
            e.printStackTrace();
        }
    }
}