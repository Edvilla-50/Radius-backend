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

    @Value("${sentdm.template.id}")
    private String templateId;

    private final RestTemplate restTemplate = new RestTemplate();
    private static final String BASE_URL = "https://api.sent.dm";

    public void sendEmergencyAlert(String toPhone, String emergencyType, double lat, double lon, String note) {
        String mapsLink = "https://www.google.com/maps/search/?api=1&query=" + lat + "," + lon;

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("x-api-key", apiKey);

        Map<String, Object> parameters = new java.util.HashMap<>();
        parameters.put("situation", emergencyType);
        parameters.put("location", mapsLink);
        if (note != null && !note.isEmpty()) {
            parameters.put("note", note);
        }

        Map<String, Object> template = Map.of(
            "id", templateId,
            "parameters", parameters
        );

        Map<String, Object> body = Map.of(
            "to", new String[]{toPhone},
            "template", template
        );

        HttpEntity<Map<String, Object>> request = new HttpEntity<>(body, headers);
        restTemplate.postForEntity(BASE_URL + "/v3/messages", request, String.class);
    }
}