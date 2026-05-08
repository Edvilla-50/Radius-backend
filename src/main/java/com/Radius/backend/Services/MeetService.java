package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.InterestEntity;
import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.User;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class MeetService {

    @Autowired
    private MeetRequestRepository repo;

    @Autowired
    private UserRepository userRepo;

    @Value("${foursquare.apiKey}")
    private String foursquareApiKey;

    // Create a new meet request
    public MeetRequest createRequest(int requesterId, int receiverId) {
        // Check if a request already exists in either direction
        Optional<MeetRequest> existingAB = repo.findByRequesterIdAndReceiverId(requesterId, receiverId);
        Optional<MeetRequest> existingBA = repo.findByRequesterIdAndReceiverId(receiverId, requesterId);

        if (existingAB.isPresent()) return existingAB.get();
        if (existingBA.isPresent()) return existingBA.get();

        // Save first to get the generated id, then use it as matchId
        MeetRequest req = new MeetRequest(requesterId, receiverId, "PENDING");
        MeetRequest saved = repo.save(req);
        saved.setMatchId(saved.getId()); // use the request's own id as the matchId
        return repo.save(saved);
    }

    // Get all incoming pending requests for a user
    public List<MeetRequest> getIncoming(int userId) {
        return repo.findByReceiverIdAndStatus(userId, "PENDING");
    }

    // Accept or decline a request
    public MeetRequest respond(int requestId, boolean accepted) {
        MeetRequest req = repo.findById(requestId).orElseThrow();
        req.setStatus(accepted ? "ACCEPTED" : "DECLINED");
        return repo.save(req);
    }

    // Check if both users have accepted each other
    public boolean isMutual(int a, int b) {
        Optional<MeetRequest> reqAB = repo.findByRequesterIdAndReceiverId(a, b);
        Optional<MeetRequest> reqBA = repo.findByRequesterIdAndReceiverId(b, a);

        boolean aAccepted = reqAB.isPresent() && "ACCEPTED".equals(reqAB.get().getStatus());
        boolean bAccepted = reqBA.isPresent() && "ACCEPTED".equals(reqBA.get().getStatus());

        return aAccepted && bAccepted;
    }

    // Find a mutual match for a user and return the matchId
    public Integer findMutualForUser(int userId) {
        // Check requests this user sent that were accepted
        List<MeetRequest> sent = repo.findByRequesterIdAndStatus(userId, "ACCEPTED");
        for (MeetRequest s : sent) {
            // Verify the other side also sent an accepted request
            Optional<MeetRequest> other = repo.findByRequesterIdAndReceiverId(s.getReceiverId(), userId);
            if (other.isPresent() && "ACCEPTED".equals(other.get().getStatus())) {
                return s.getMatchId();
            }
        }

        // Check requests this user received that they accepted
        List<MeetRequest> received = repo.findByReceiverIdAndStatus(userId, "ACCEPTED");
        for (MeetRequest r : received) {
            // Verify the other side also sent an accepted request
            Optional<MeetRequest> other = repo.findByRequesterIdAndReceiverId(r.getRequesterId(), userId);
            if (other.isPresent() && "ACCEPTED".equals(other.get().getStatus())) {
                return r.getMatchId();
            }
        }

        return null;
    }

    public Map<String, Double> getMidpoint(int userA, int userB) {
        User a = userRepo.findById((long) userA).orElseThrow();
        User b = userRepo.findById((long) userB).orElseThrow();

        double midLat = (a.getLat() + b.getLat()) / 2.0;
        double midLon = (a.getLon() + b.getLon()) / 2.0;

        Map<String, Double> map = new HashMap<>();
        map.put("lat", midLat);
        map.put("lon", midLon);
        return map;
    }

    public Map<String, Object> getSuggestions(double lat, double lon) {
        String url = UriComponentsBuilder
                .fromUriString("https://places-api.foursquare.com/places/search")
                .queryParam("ll", lat + "," + lon)
                .queryParam("radius", 1500)
                .queryParam("limit", 10)
                .toUriString();

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + foursquareApiKey.trim());
        headers.set("X-Places-Api-Version", "2025-06-17");
        headers.set("Accept", "application/json");

        HttpEntity<String> entity = new HttpEntity<>(headers);
        RestTemplate rest = new RestTemplate();
        ResponseEntity<Map> response = rest.exchange(url, HttpMethod.GET, entity, Map.class);
        return response.getBody();
    }

    public Map<String, Object> getSuggestionsByQuery(double lat, double lon, String query) {
        String url = UriComponentsBuilder
                .fromUriString("https://places-api.foursquare.com/places/search")
                .queryParam("ll", lat + "," + lon)
                .queryParam("query", query)
                .queryParam("radius", 1500)
                .queryParam("limit", 10)
                .toUriString();

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + foursquareApiKey.trim());
        headers.set("X-Places-Api-Version", "2025-06-17");
        headers.set("Accept", "application/json");

        HttpEntity<String> entity = new HttpEntity<>(headers);
        RestTemplate rest = new RestTemplate();
        ResponseEntity<Map> response = rest.exchange(url, HttpMethod.GET, entity, Map.class);
        return response.getBody();
    }

    public List<String> getSharedCategories(int userA, int userB) {
        User a = userRepo.findById((long) userA).orElseThrow();
        User b = userRepo.findById((long) userB).orElseThrow();

        List<String> categoriesA = a.getInterests().stream()
                .map(InterestEntity::getCategory)
                .filter(c -> c != null && !c.isBlank())
                .toList();

        List<String> categoriesB = b.getInterests().stream()
                .map(InterestEntity::getCategory)
                .filter(c -> c != null && !c.isBlank())
                .toList();

        return categoriesA.stream().filter(categoriesB::contains).distinct().toList();
    }

    public Map<String, Object> getSuggestionsForUsers(int userA, int userB) {
        Map<String, Double> mid = getMidpoint(userA, userB);
        double lat = mid.get("lat");
        double lon = mid.get("lon");

        List<String> shared = getSharedCategories(userA, userB);

        if (shared.isEmpty()) {
            return getSuggestions(lat, lon);
        }

        String query = mapCategoryToQuery(shared.get(0));
        return getSuggestionsByQuery(lat, lon, query);
    }

    private String mapCategoryToQuery(String category) {
        return switch (category.toLowerCase()) {
            case "coffee" -> "coffee";
            case "food", "restaurant", "foodie" -> "restaurant";
            case "gym", "fitness" -> "gym";
            case "park", "hiking", "outdoors" -> "park";
            case "library", "studying" -> "library";
            case "bookstore", "anime" -> "bookstore";
            case "music", "concert" -> "music";
            case "cinema", "movies" -> "cinema";
            case "bowling" -> "bowling";
            default -> "popular";
        };
    }
}


