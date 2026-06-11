package com.Radius.backend.Services;

import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import org.springframework.stereotype.Service;

@Service
public class NotificationService {

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) return;

        try {
            Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(Notification.builder()
                    .setTitle("New Meetup Request 👋")
                    .setBody(requesterName + " wants to meet up with you!")
                    .build())
                .build();

            FirebaseMessaging.getInstance().send(message);
        } catch (Exception e) {
            System.err.println("Failed to send FCM notification: " + e.getMessage());
        }
    }
}
