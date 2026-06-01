package com.Radius.backend.Services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.*;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

@Service
public class SentDmService {

    @Value("${sentdm.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String BASE_URL = "https://api.sent.dm";

    public void sendEmergencyAlert(String toPhone, String emergencyType, double lat, double lon, String note) {
        String mapsLink = "https://www.google.com/maps/search/?api=1&query=" + lat + "," + lon;

        String message = "EMERGENCY ALERT: " +
            "Situation: " + emergencyType + "\n" +
            "Location: " + mapsLink + "\n" +
            (note != null && !note.isEmpty() ? "Note: " + note : "");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("x-api-key", apiKey);

        Map<String, String> body = Map.of(
            "to", toPhone,
            "message", message
        );

        HttpEntity<Map<String, String>> request = new HttpEntity<>(body, headers);
        restTemplate.postForEntity(BASE_URL + "/send", request, String.class);
    }
}