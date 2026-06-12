package com.Radius.backend.Services;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;

@Service
public class NotificationService {

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping");
            return;
        }

        try {
            // FORCE CHECK: If Firebase didn't initialize at app startup, initialize it right here
            if (FirebaseApp.getApps().isEmpty()) {
                System.out.println(">>> Firebase wasn't initialized! Forcing local initialization... <<<");
                
                FileInputStream serviceAccount = 
                    new FileInputStream("/etc/secrets/firebase-service-account.json");

                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

                FirebaseApp.initializeApp(options);
                System.out.println(">>> Forced Local Firebase Initialization Complete <<<");
            }

            // Build the message payload
            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            // Send the notification
            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("FCM send success! Message ID: " + response);

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification via SDK: " + e.getMessage());
            e.printStackTrace();
        }
    }
}