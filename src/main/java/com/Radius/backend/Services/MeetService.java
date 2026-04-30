package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.InterestEntity;
import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.User;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
@Service
public class MeetService {
    @Autowired
    private MeetRequestRepository repo;
    @Value("${foursquare.apiKey}")
    private String foursquareApiKey;

    //create a new meet request
    public MeetRequest createRequest(int requesterId, int recieverId){
        MeetRequest req = new MeetRequest(requesterId, recieverId, "PENDING");
        return repo.save(req);
    }
    //Get all incoming pending requests for a user
    public List<MeetRequest> getIncoming(int userId){
        return repo.findByReceiverIdAndStatus(userId, "PENDING");
    }
    //accept or decline request
    public MeetRequest respond(int requestId, boolean accepted){
        MeetRequest req = repo.findById(requestId).orElseThrow();
        req.setStatus(accepted ? "ACCEPTED": "DECLINED");
        return repo.save(req);
    }
    //checks if both accept each other
    public boolean isMutual(int requesterId, int receiverId){
        List<MeetRequest> a = repo.findByRequesterIdAndStatus(requesterId, "ACCEPTED");
        List<MeetRequest> b = repo.findByReceiverIdAndStatus(receiverId, "ACCEPTED");

        return !a.isEmpty() && !b.isEmpty();
    }

    @Autowired
    private UserRepository userRepo;

    public Map<String, Double> getMidpoint(int userA, int userB){
        User a = userRepo.findById((long) userA).orElseThrow();
        User b = userRepo.findById((long) userB).orElseThrow();

        double midLat = (a.getLat()+b.getLat()) /2.0;
        double midLon = (a.getLon()+b.getLon()) / 2.0;

        Map<String,  Double> map = new HashMap<>();
        map.put("lat", midLat);
        map.put("lon", midLon);
        return map;
    }
    public JsonNode getSuggestions(double lat, double lon) {
        String url = "https://api.foursquare.com/v3/places/search?ll=" 
                    + lat + "," + lon + "&radius=1500&limit=10";

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", foursquareApiKey);
        HttpEntity<String> entity = new HttpEntity<>(headers);

        RestTemplate rest = new RestTemplate();
        ResponseEntity<JsonNode> response = rest.exchange(url, HttpMethod.GET, entity, JsonNode.class);

        return response.getBody();
    }
    public List<String> getSharedCategories(int userA, int userB) {
        User a = userRepo.findById((long) userA).orElseThrow();
        User b = userRepo.findById((long) userB).orElseThrow();

        List<String> categoriesA = a.getInterests().stream().map(InterestEntity::getCategory).filter(c -> c != null && !c.isBlank()).toList();

        List<String> categoriesB = b.getInterests().stream().map(InterestEntity::getCategory).filter(c -> c != null && !c.isBlank()).toList();

        return categoriesA.stream().filter(categoriesB::contains).distinct().toList();
    }
    public JsonNode getSuggestionsByQuery(double lat, double lon, String query) {
        String url = "https://api.foursquare.com/v3/places/search?ll="+ lat + "," + lon + "&query=" + query + "&radius=1500&limit=10";

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", foursquareApiKey);

        HttpEntity<String> entity = new HttpEntity<>(headers);

        RestTemplate rest = new RestTemplate();
        ResponseEntity<JsonNode> response = rest.exchange(url, HttpMethod.GET, entity, JsonNode.class);

        return response.getBody();
    }
    public JsonNode getSuggestionsForUsers(int userA, int userB) {
        Map<String, Double> mid = getMidpoint(userA, userB);
        double lat = mid.get("lat");
        double lon = mid.get("lon");

        List<String> shared = getSharedCategories(userA, userB);

        // If no shared interests → fallback to generic suggestions
        if (shared.isEmpty()) {
            return getSuggestions(lat, lon);
        }
        
        // Use the first shared category for now
        String category = shared.get(0);
        String query = mapCategoryToQuery(category);

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


