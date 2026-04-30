package com.Radius.backend.Services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.ParameterizedTypeReference;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.http.*;

import java.util.*;

@Service
public class FourSquareService {

    // 🔐 This MUST be your SERVICE KEY (not fsq3...)
    @Value("${foursquare.apiKey}")
    private String apiKey = "RO5ZMGLCR33VA4U2XFRQCOMUKWTMMJ2R0K0AGUAGCFGSQAQO";

    public List<Map<String, Object>> getNearbyPlaces(double lat, double lon) {
    System.out.println("FOURSQUARE KEY LOADED: " + apiKey);
    String url = UriComponentsBuilder
            .fromUriString("https://places-api.foursquare.com/places/search")
            .queryParam("ll", lat + "," + lon)
            .queryParam("limit", 10)
            .toUriString();

    RestTemplate restTemplate = new RestTemplate();

    HttpHeaders headers = new HttpHeaders();

    headers.set("Authorization", "Bearer " + apiKey.trim());
    headers.set("X-Places-Api-Version", "2025-06-17");
    headers.set("Accept", "application/json");
    


    HttpEntity<String> entity = new HttpEntity<>(headers);

    try {
        ResponseEntity<Map> response = restTemplate.exchange(
                url,
                HttpMethod.GET,
                entity,
                Map.class
        );

        Map body = response.getBody();

        if (body == null || !body.containsKey("results")) {
            return new ArrayList<>();
        }

        return (List<Map<String, Object>>) body.get("results");

    } catch (Exception e) {
        e.printStackTrace();
        throw new RuntimeException("Foursquare failed", e);
    }
    }
}