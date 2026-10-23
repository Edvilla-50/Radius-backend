package com.Radius.backend.Services;

import com.Radius.backend.dto.OverpassElement;
import com.Radius.backend.dto.OverpassResponse;
import com.Radius.backend.dto.PlaceLocation;
import com.Radius.backend.dto.SuggestedPlace;
import com.Radius.backend.dto.SuggestionsResponse;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.client.JdkClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OverpassPlacesService {

    // Tried in order. The last one that worked is tried first next time.
    // These are community-run servers; swap any that go away.
    private static final List<String> OVERPASS_URLS = List.of(
            "https://z.overpass-api.de/api/interpreter",
            "https://lz4.overpass-api.de/api/interpreter",
            "https://overpass-api.de/api/interpreter",
            "https://overpass.kumi.systems/api/interpreter",
            "https://overpass.private.coffee/api/interpreter"
    );

    // Overpass operators block anonymous/default Java user agents.
    private static final String USER_AGENT =
            "Radius/1.0 (+https://radius-create.com; support@radius-create.com)";

    private static final String AMENITY_TAGS = "cafe|restaurant|bar|pub|fast_food|library";
    private static final String LEISURE_TAGS = "park|fitness_centre|sports_centre";

    private static final long CACHE_TTL_MS = 6 * 60 * 60 * 1000L;

    private record CachedPlaces(List<SuggestedPlace> places, long cachedAt) {}

    private final Map<String, CachedPlaces> placeCache = new ConcurrentHashMap<>();
    private volatile int preferredIndex = 0;

    private final RestTemplate restTemplate;

    public OverpassPlacesService() {
        // Own RestTemplate with increased timeouts and redirect handling
        HttpClient httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(15))
                .followRedirects(HttpClient.Redirect.NORMAL)
                .build();
        JdkClientHttpRequestFactory factory = new JdkClientHttpRequestFactory(httpClient);
        factory.setReadTimeout(Duration.ofSeconds(60));
        this.restTemplate = new RestTemplate(factory);
    }

    public SuggestionsResponse findPlacesForInterests(double lat, double lon, int radius, List<Map<String, String>> tagFilters) {
        radius = Math.max(100, Math.min(radius, 5000));
        List<SuggestedPlace> places = List.of();

        if (!tagFilters.isEmpty()) {
            String key = cacheKey(lat, lon, radius, "interest:" + tagFilters);
            places = lookup(key, buildInterestQuery(lat, lon, radius, tagFilters));
        }

        if (places.isEmpty()) {
            return findNearbyPlaces(lat, lon, radius);
        }

        return new SuggestionsResponse(places);
    }

    public SuggestionsResponse findNearbyPlaces(double lat, double lon, int radius) {
        radius = Math.max(100, Math.min(radius, 5000));
        String key = cacheKey(lat, lon, radius, "fallback");
        return new SuggestionsResponse(lookup(key, buildFallbackQuery(lat, lon, radius)));
    }

    // ---------------- CACHE ----------------

    private String cacheKey(double lat, double lon, int radius, String variant) {
        // 3 decimals is roughly 110 m, so nearby midpoints share results.
        return String.format(Locale.US, "%.3f,%.3f,%d,%s", lat, lon, radius, variant);
    }

    private List<SuggestedPlace> lookup(String key, String query) {
        CachedPlaces hit = placeCache.get(key);
        if (hit != null && System.currentTimeMillis() - hit.cachedAt() < CACHE_TTL_MS) {
            return hit.places();
        }

        List<SuggestedPlace> places = mapToSuggestedPlaces(callOverpass(query));

        // Never cache an empty answer.
        if (!places.isEmpty()) {
            placeCache.put(key, new CachedPlaces(places, System.currentTimeMillis()));
        }
        return places;
    }

    // ---------------- OVERPASS CALL (with failover) ----------------

    private OverpassResponse callOverpass(String query) {
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        headers.setAccept(List.of(MediaType.APPLICATION_JSON));
        headers.set(HttpHeaders.USER_AGENT, USER_AGENT);
        headers.set(HttpHeaders.REFERER, "https://radius-create.com");
        
        // Avoid reusing potentially bad keep-alive connections.
        headers.set("Connection", "close");

        HttpEntity<String> request = new HttpEntity<>(
                "data=" + URLEncoder.encode(query, StandardCharsets.UTF_8), headers);

        RuntimeException lastError = null;
        int start = preferredIndex;

        for (int i = 0; i < OVERPASS_URLS.size(); i++) {
            int idx = (start + i) % OVERPASS_URLS.size();
            String url = OVERPASS_URLS.get(idx);
            try {
                System.out.println("Trying Overpass endpoint: " + url);
                OverpassResponse response =
                        restTemplate.postForObject(url, request, OverpassResponse.class);
                if (response != null && response.elements() != null) {
                    System.out.println(
                            "Overpass success from " + url +
                                    " with " + response.elements().size() +
                                    " elements"
                    );
                    preferredIndex = idx;
                    return response;
                }
                System.out.println("Overpass " + url + " returned null or empty response");
            } catch (Exception e) {
                lastError = new RuntimeException(e);
                System.err.println("Overpass " + url + " failed: " + e.getClass().getName());
                e.printStackTrace();
            }
        }

        // Every server failed: let the caller's retry logic see the error.
        if (lastError != null) throw lastError;
        return null;
    }

    // ---------------- QUERIES ----------------

    private String buildInterestQuery(double lat, double lon, int radius, List<Map<String, String>> tagFilters) {
        StringBuilder qb = new StringBuilder();
        qb.append("[out:json][timeout:15];\n(\n");

        for (Map<String, String> filter : tagFilters) {
            qb.append("  nwr");
            for (Map.Entry<String, String> entry : filter.entrySet()) {
                qb.append(String.format("[\"%s\"=\"%s\"]", entry.getKey(), entry.getValue()));
            }
            qb.append(String.format(Locale.US, "(around:%d,%f,%f);%n", radius, lat, lon));
        }

        qb.append(");\nout center;\n");
        return qb.toString();
    }

    private String buildFallbackQuery(double lat, double lon, int radius) {
        return String.format(Locale.US, """
                [out:json][timeout:15];
                (
                  nwr["amenity"~"%s"](around:%d,%f,%f);
                  nwr["leisure"~"%s"](around:%d,%f,%f);
                );
                out center;
                """,
                AMENITY_TAGS, radius, lat, lon,
                LEISURE_TAGS, radius, lat, lon);
    }

    // ---------------- MAPPING ----------------

    private List<SuggestedPlace> mapToSuggestedPlaces(OverpassResponse response) {
        List<SuggestedPlace> places = new ArrayList<>();
        if (response == null || response.elements() == null) {
            return places;
        }

        for (OverpassElement element : response.elements()) {
            Map<String, String> tags = element.tags();
            String name = tags == null ? null : tags.get("name");
            if (name == null || name.equalsIgnoreCase("unbranded")) {
                continue;
            }
            double placeLat = 0.0;
            double placeLon = 0.0;

            // 1. Check top-level elements first (Safely handles Double object wrappers)
            if (element.lat() != null && !element.lat().equals(0.0)) {
                placeLat = element.lat();
                placeLon = element.lon();
            }
            // 2. Fall back to the nested center block
            else if (element.center() != null) {
                Object rawLat = element.center().lat();
                Object rawLon = element.center().lon();

                if (rawLat != null && rawLon != null) {
                    placeLat = ((Number) rawLat).doubleValue();
                    placeLon = ((Number) rawLon).doubleValue();
                }
            }

            // Drop values that lack proper coordinates to protect the Flutter Map UI
            if (placeLat == 0.0 || placeLon == 0.0) {
                continue;
            }

            places.add(new SuggestedPlace(
                    String.valueOf(element.id()),
                    name,
                    new PlaceLocation(buildFormattedAddress(tags)),
                    placeLat,
                    placeLon
            ));
        }

        return places;
    }

    private String buildFormattedAddress(Map<String, String> tags) {
        if (tags == null) return "Address unavailable";

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

        return sb.length() > 0 ? sb.toString() : "Address unavailable";
    }
}