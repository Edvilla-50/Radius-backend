package com.Radius.backend.Services;

import com.Radius.backend.dto.OverpassElement;
import com.Radius.backend.dto.OverpassResponse;
import com.Radius.backend.dto.PlaceLocation;
import com.Radius.backend.dto.SuggestedPlace;
import com.Radius.backend.dto.SuggestionsResponse;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class OverpassPlacesService {

    private static final String OVERPASS_URL = "https://overpass-api.de/api/interpreter";

    // Tune these to whatever categories make sense for Radius meetups
    private static final String AMENITY_TAGS = "cafe|restaurant|bar|pub|fast_food|library";
    private static final String LEISURE_TAGS = "park|fitness_centre|sports_centre";

    private final RestTemplate restTemplate;

    public OverpassPlacesService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    public SuggestionsResponse findPlacesForInterests(double lat, double lon, int radius, List<String> sharedInterests) {
            System.out.println("=== OVERPASS DEBUG ===");
        System.out.println("Lat: " + lat);
        System.out.println("Lon: " + lon);
        System.out.println("Radius: " + radius);
        System.out.println("Shared interests: " + sharedInterests);
            List<Map<String, String>> tagFilters = InterestTagMapper.resolveTagFilters(sharedInterests);

        List<SuggestedPlace> places = List.of();
        if (!tagFilters.isEmpty()) {
            OverpassResponse response = callOverpass(buildInterestQuery(lat, lon, radius, tagFilters));
            places = mapToSuggestedPlaces(response);
        }

        if (places.isEmpty()) {
            return findNearbyPlaces(lat, lon, radius);
        }

        return new SuggestionsResponse(places);
    }

    public SuggestionsResponse findNearbyPlaces(double lat, double lon, int radius) {
        OverpassResponse response = callOverpass(buildFallbackQuery(lat, lon, radius));
        return new SuggestionsResponse(mapToSuggestedPlaces(response));
    }

    private OverpassResponse callOverpass(String query) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        HttpEntity<String> request = new HttpEntity<>("data=" + query, headers);

        return restTemplate.postForObject(OVERPASS_URL, request, OverpassResponse.class);
    }

    private String buildInterestQuery(double lat, double lon, int radius, List<Map<String, String>> tagFilters) {
        StringBuilder qb = new StringBuilder();
        qb.append("[out:json][timeout:25];\n(\n");

        for (Map<String, String> filter : tagFilters) {
            qb.append("  node");
            for (Map.Entry<String, String> entry : filter.entrySet()) {
                qb.append(String.format("[\"%s\"=\"%s\"]", entry.getKey(), entry.getValue()));
            }
            qb.append(String.format("(around:%d,%f,%f);%n", radius, lat, lon));
        }

        qb.append(");\nout body;\n");
        return qb.toString();
    }

    private String buildFallbackQuery(double lat, double lon, int radius) {
        return String.format("""
                [out:json][timeout:25];
                (
                  node["amenity"~"%s"](around:%d,%f,%f);
                  node["leisure"~"%s"](around:%d,%f,%f);
                );
                out body;
                """,
                AMENITY_TAGS, radius, lat, lon,
                LEISURE_TAGS, radius, lat, lon);
    }

    private List<SuggestedPlace> mapToSuggestedPlaces(OverpassResponse response) {
        List<SuggestedPlace> places = new ArrayList<>();
        if (response == null || response.elements() == null) {
            return places;
        }

        for (OverpassElement element : response.elements()) {
            Map<String, String> tags = element.tags();
            String name = tags == null ? null : tags.get("name");
            if (name == null || name.equalsIgnoreCase("unbranded")) {
                continue; // skip unnamed nodes and OSM's "unbranded" placeholder
            }

            places.add(new SuggestedPlace(
                    String.valueOf(element.id()),
                    name,
                    new PlaceLocation(buildFormattedAddress(tags)),
                    element.lat(),
                    element.lon()
            ));
        }

        return places;
    }

    private String buildFormattedAddress(Map<String, String> tags) {
        if (tags == null) return null;

        String houseNumber = tags.get("addr:housenumber");
        String street = tags.get("addr:street");
        String city = tags.get("addr:city");
        String state = tags.get("addr:state");

        StringBuilder sb = new StringBuilder();
        if (houseNumber != null && street != null) {
            sb.append(houseNumber).append(" ").append(street);
        } else if (street != null) {
            sb.append(street);
        }
        if (city != null) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(city);
        }
        if (state != null) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(state);
        }

        return sb.length() > 0 ? sb.toString() : null;
    }
}