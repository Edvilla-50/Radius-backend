package com.Radius.backend.Services;

import com.google.auth.oauth2.GoogleCredentials;
import org.springframework.stereotype.Service;

import java.io.FileInputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Collections;

@Service
public class NotificationService {

    private final HttpClient httpClient = HttpClient.newHttpClient();

    public void sendMeetupRequestNotification(String fcmToken, String requesterName) {
        if (fcmToken == null || fcmToken.isEmpty()) {
            System.err.println("FCM token is null or empty — skipping");
            return;
        }

        try {
            System.out.println(">>> Requesting fresh OAuth2 token explicitly from Google IAM... <<<");
            String path = "/etc/secrets/firebase-service-account.json";
            FileInputStream serviceAccount = new FileInputStream(path);

            // Fetch the specific messaging scope token
            GoogleCredentials credentials = GoogleCredentials.fromStream(serviceAccount)
                .createScoped(Collections.singletonList("https://www.googleapis.com/auth/firebase.messaging"));
            
            credentials.refresh();
            String accessToken = credentials.getAccessToken().getTokenValue();
            System.out.println(">>> Token successfully minted! Sending raw HTTP payload... <<<");

            // Build the standard Firebase v1 JSON Payload
            String jsonPayload = """
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

            // Construct raw HTTP Request using the working access token
            HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://fcm.googleapis.com/v1/projects/radius-6ad92/messages:send"))
                .header("Authorization", "Bearer " + accessToken)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                .build();

            // Fire and check response code
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() == 200) {
                System.out.println("FCM send success via Raw HTTP! Response: " + response.body());
            } else {
                System.err.println("FCM send failed with status " + response.statusCode() + ": " + response.body());
            }

        } catch (Exception e) {
            System.err.println("Failed to send FCM notification via manual HTTP fallback: " + e.getMessage());
            e.printStackTrace();
        }
    }
}