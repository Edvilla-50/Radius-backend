package com.Radius.backend.Services;

import com.google.auth.oauth2.GoogleCredentials;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.List;

@Service
public class NotificationService {

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping");
            return;
        }

        try {
            // Get OAuth2 token directly from service account file
            GoogleCredentials credentials = GoogleCredentials
                .fromStream(new FileInputStream("/etc/secrets/firebase-service-account.json"))
                .createScoped(List.of("https://www.googleapis.com/auth/firebase.messaging"));

            credentials.refreshIfExpired();
            String accessToken = credentials.getAccessToken().getTokenValue();
            System.out.println("Got access token: " + accessToken.substring(0, 20) + "...");

            // Call FCM HTTP v1 API directly
            String projectId = "radius-6ad92";
            URL url = new URL("https://fcm.googleapis.com/v1/projects/" + projectId + "/messages:send");
            HttpURLConnection conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Authorization", "Bearer " + accessToken);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setDoOutput(true);

            String body = """
                {
                  "message": {
                    "token": "%s",
                    "notification": {
                      "title": "New Meetup Request 👋",
                      "body": "%s wants to meet up with you!"
                    }
                  }
                }
                """.formatted(fcmToken, requesterName);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(body.getBytes(StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();
            System.out.println("FCM response code: " + responseCode);

            if (responseCode == 200) {
                System.out.println("FCM send success!");
            } else {
                System.err.println("FCM send failed: " + new String(conn.getErrorStream().readAllBytes()));
            }

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification: " + e.getMessage());
            e.printStackTrace();
        }
    }
}