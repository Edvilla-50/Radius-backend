package com.Radius.backend.Services;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;
import java.util.*;

@Service
public class FourSquareService {

    @Value("${foursquare.api.key}")
    private String apiKey;

    public List<Map<String, Object>> getNearbyPlaces(double lat, double lon) {
        String url = String.format(
            "https://api.foursquare.com/v3/places/search?ll=%s,%s&radius=1000&limit=5&categories=13065,16000,10000",
            lat, lon
        );

        RestTemplate restTemplate = new RestTemplate();
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", apiKey);
        headers.set("Accept", "application/json");

        HttpEntity<String> entity = new HttpEntity<>(headers);
        ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, entity, Map.class);

        List<Map<String, Object>> results = (List<Map<String, Object>>) response.getBody().get("results");
        return results != null ? results : new ArrayList<>();
    }
}