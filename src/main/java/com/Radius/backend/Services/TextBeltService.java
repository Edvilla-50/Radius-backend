package com.Radius.backend.Services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.http.*;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;

@Service
public class TextBeltService {

    @Value("${textbelt.api.key}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String BASE_URL = "https://textbelt.com/text";

    public void sendEmergencyAlert(String toPhone, String emergencyType, double lat, double lon, String note) {
        String message = "EMERGENCY ALERT\n" +
            "Situation: " + emergencyType + "\n" +
            "Lat: " + lat + ", Lon: " + lon +
            (note != null && !note.isEmpty() ? "\nNote: " + note : "");

        MultiValueMap<String, String> body = new LinkedMultiValueMap<>();
        body.add("phone", toPhone);
        body.add("message", message);
        body.add("key", apiKey);
        body.add("sender", "Radius");

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);

        HttpEntity<MultiValueMap<String, String>> request = new HttpEntity<>(body, headers);
        ResponseEntity<String> response = restTemplate.postForEntity(BASE_URL, request, String.class);
        System.out.println("TextBelt response: " + response.getStatusCode() + " - " + response.getBody());
    }
}