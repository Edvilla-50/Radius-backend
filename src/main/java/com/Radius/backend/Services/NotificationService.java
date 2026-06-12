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
            String path = "/etc/secrets/firebase-service-account.json";
            String appName = "RadiusScopedApp";
            FirebaseApp scopedApp;

            try {
                scopedApp = FirebaseApp.getInstance(appName);
            } catch (IllegalStateException e) {
                System.out.println(">>> Initializing isolated Firebase instance for notification routing... <<<");
                FileInputStream serviceAccount = new FileInputStream(path);
                
                FirebaseOptions options = FirebaseOptions.builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                    .build();

                scopedApp = FirebaseApp.initializeApp(options, appName);
            }

            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            // CRITICAL FIX: You must pass scopedApp here so the SDK signs the request token!
            String response = FirebaseMessaging.getInstance(scopedApp).send(message);
            System.out.println("FCM send success! Message ID: " + response);

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification via SDK: " + e.getMessage());
            e.printStackTrace();
        }
    }
}