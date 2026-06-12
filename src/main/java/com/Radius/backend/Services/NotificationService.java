package com.Radius.backend.Services;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class NotificationService {

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping notification");
            return;
        }

        System.out.println("Attempting FCM send to token: " + fcmToken.substring(0, 20) + "...");

        try {
            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            String response = FirebaseMessaging.getInstance().send(message);
            System.out.println("FCM send success: " + response);
        } catch (Exception e) {
            System.err.println("Failed to send FCM notification: " + e.getMessage());
            e.printStackTrace();
        }
    }
}