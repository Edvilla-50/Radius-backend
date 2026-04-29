package com.Radius.backend.Services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;

import java.util.*;

@Service
public class FourSquareService {

    // 🔐 This MUST be your SERVICE KEY (not fsq3...)
    @Value("${foursquare.api.key}")
    private String apiKey;

    public List<Map<String, Object>> getNearbyPlaces(double lat, double lon) {

        String url = String.format(
            "https://places-api.foursquare.com/places/search?ll=%f,%f&radius=1000&limit=5",
            lat, lon
        );

        RestTemplate restTemplate = new RestTemplate();

        // ✅ Headers for NEW API
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + apiKey); // <-- MUST be Bearer
        headers.set("Accept", "application/json");
        headers.set("X-Places-Api-Version", "2025-06-17"); // <-- REQUIRED

        HttpEntity<String> entity = new HttpEntity<>(headers);

        try {
            ResponseEntity<Map<String, Object>> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                new ParameterizedTypeReference<Map<String, Object>>() {}
            );

            Map<String, Object> body = response.getBody();

            if (body == null || !body.containsKey("results")) {
                System.out.println("⚠️ No results found in response: " + body);
                return new ArrayList<>();
            }

            return (List<Map<String, Object>>) body.get("results");

        } catch (Exception e) {
            System.out.println("❌ Foursquare API error: " + e.getMessage());
            return new ArrayList<>();
        }
    }
}