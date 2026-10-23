package com.Radius.backend.Services;

import com.Radius.backend.dto.PlaceLocation;
import com.Radius.backend.dto.SuggestedPlace;
import com.Radius.backend.dto.SuggestionsResponse;
import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.springframework.http.client.SimpleClientHttpRequestFactory;

@Service
public class OverpassPlacesService {

    private static final String GEOAPIFY_URL = "https://api.geoapify.com/v2/places";

    // FIXED: Replaced unsupported "activity.fitness_club" with valid "sport.fitness.gym"
    private static final String DEFAULT_CATEGORIES = 
            "catering.cafe,catering.restaurant,catering.bar,catering.pub,catering.fast_food,education.library,leisure.park,sport.fitness.gym,sport_center";

    private static final long CACHE_TTL_MS = 6 * 60 * 60 * 1000L;

    private record CachedPlaces(List<SuggestedPlace> places, long cachedAt) {}
    private final Map<String, CachedPlaces> placeCache = new ConcurrentHashMap<>();

    private final RestTemplate restTemplate;
    
    @Value("${geoapify.api.key}")
    private String apiKey;

    public OverpassPlacesService() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(15000);
        factory.setReadTimeout(30000);
        this.restTemplate = new RestTemplate(factory);
    }

    public SuggestionsResponse findPlacesForInterests(double lat, double lon, int radius, List<Map<String, String>> tagFilters) {
        radius = Math.max(100, Math.min(radius, 5000));
        List<SuggestedPlace> places = List.of();

        if (!tagFilters.isEmpty()) {
            String categories = mapFiltersToGeoapifyCategories(tagFilters);
            String key = cacheKey(lat, lon, radius, "interest:" + categories);
            places = lookup(key, lat, lon, radius, categories);
        }

        if (places.isEmpty()) {
            return findNearbyPlaces(lat, lon, radius);
        }

        return new SuggestionsResponse(places);
    }

    public SuggestionsResponse findNearbyPlaces(double lat, double lon, int radius) {
        radius = Math.max(100, Math.min(radius, 5000));
        String key = cacheKey(lat, lon, radius, "fallback");
        return new SuggestionsResponse(lookup(key, lat, lon, radius, DEFAULT_CATEGORIES));
    }

    // ---------------- CACHE ----------------

    private String cacheKey(double lat, double lon, int radius, String variant) {
        return String.format(Locale.US, "%.3f,%.3f,%d,%s", lat, lon, radius, variant);
    }

    private List<SuggestedPlace> lookup(String key, double lat, double lon, int radius, String categories) {
        CachedPlaces hit = placeCache.get(key);
        if (hit != null && System.currentTimeMillis() - hit.cachedAt() < CACHE_TTL_MS) {
            return hit.places();
        }

        List<SuggestedPlace> places = callGeoapify(lat, lon, radius, categories);

        if (!places.isEmpty()) {
            placeCache.put(key, new CachedPlaces(places, System.currentTimeMillis()));
        }
        return places;
    }

    // ---------------- GEOAPIFY API CALL ----------------

    private List<SuggestedPlace> callGeoapify(double lat, double lon, int radius, String categories) {
        List<SuggestedPlace> places = new ArrayList<>();
        try {
            String filterParam = String.format(Locale.US, "circle:%.6f,%.6f,%d", lon, lat, radius);

            String url = UriComponentsBuilder.fromUriString(GEOAPIFY_URL)
                    .queryParam("categories", categories)
                    .queryParam("filter", filterParam)
                    .queryParam("limit", 50)
                    .queryParam("apiKey", apiKey)
                    .toUriString();

            System.out.println("Calling Geoapify API with categories: " + categories);
            ResponseEntity<JsonNode> response = restTemplate.getForEntity(url, JsonNode.class);
            JsonNode root = response.getBody();

            if (root != null && root.has("features")) {
                for (JsonNode feature : root.get("features")) {
                    JsonNode properties = feature.get("properties");
                    JsonNode geometry = feature.get("geometry");

                    if (properties == null || geometry == null) continue;

                    String name = properties.has("name") ? properties.get("name").asText() : null;
                    if (name == null || name.equalsIgnoreCase("unbranded")) continue;

                    String placeId = properties.has("place_id") ? properties.get("place_id").asText() : java.util.UUID.randomUUID().toString();
                    String address = properties.has("formatted") ? properties.get("formatted").asText() : "Address unavailable";

                    JsonNode coords = geometry.get("coordinates");
                    if (coords == null || coords.size() < 2) continue;

                    double placeLon = coords.get(0).asDouble();
                    double placeLat = coords.get(1).asDouble();

                    places.add(new SuggestedPlace(
                            placeId,
                            name,
                            new PlaceLocation(address),
                            placeLat,
                            placeLon
                    ));
                }
            }
            System.out.println("Geoapify success: found " + places.size() + " places.");
        } catch (Exception e) {
            System.err.println("Geoapify request failed: " + e.getMessage());
            // SAFETY FALLBACK: If a custom category fails with 400 Bad Request, retry once using safe defaults
            if (!categories.equals(DEFAULT_CATEGORIES)) {
                System.out.println("Retrying with default safe categories...");
                return callGeoapify(lat, lon, radius, DEFAULT_CATEGORIES);
            }
        }
        return places;
    }

    // ---------------- MAPPING FILTERS ----------------

    private String mapFiltersToGeoapifyCategories(List<Map<String, String>> tagFilters) {
        List<String> mappedCategories = new ArrayList<>();
        for (Map<String, String> filter : tagFilters) {
            String amenity = filter.get("amenity");
            String leisure = filter.get("leisure");

            if ("cafe".equals(amenity)) mappedCategories.add("catering.cafe");
            else if ("restaurant".equals(amenity)) mappedCategories.add("catering.restaurant");
            else if ("bar".equals(amenity)) mappedCategories.add("catering.bar");
            else if ("pub".equals(amenity)) mappedCategories.add("catering.pub");
            else if ("fast_food".equals(amenity)) mappedCategories.add("catering.fast_food");
            else if ("library".equals(amenity)) mappedCategories.add("education.library");
            else if ("park".equals(leisure)) mappedCategories.add("leisure.park");
            // FIXED: Map fitness/sports correctly to Geoapify's standard
            else if ("fitness_centre".equals(leisure) || "sports_centre".equals(leisure) || "gym".equals(amenity)) {
                mappedCategories.add("sport.fitness.gym");
            }
        }
        return mappedCategories.isEmpty() ? DEFAULT_CATEGORIES : String.join(",", mappedCategories);
    }
}