package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.InterestEntity;
import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.User;
import com.Radius.backend.dto.SuggestionsResponse;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
public class MeetService {

    @Autowired
    private MeetRequestRepository repo;

    @Autowired
    private UserRepository userRepo;

    @Autowired
    private NotificationService notificationService;

    @Autowired
    private OverpassPlacesService overpassPlacesService;

    // ---------------- CREATE REQUEST ----------------

    public MeetRequest createRequest(int requesterId, int receiverId) {
        Optional<MeetRequest> existingAB =
                repo.findByRequesterIdAndReceiverId(requesterId, receiverId);
        Optional<MeetRequest> existingBA =
                repo.findByRequesterIdAndReceiverId(receiverId, requesterId);

        if (existingAB.isPresent()) return existingAB.get();
        if (existingBA.isPresent()) return existingBA.get();

        MeetRequest req = new MeetRequest(requesterId, receiverId, "PENDING");
        MeetRequest saved = repo.save(req);

        saved.setMatchId(saved.getId());
        repo.save(saved);

        User requester = userRepo.findById((long) requesterId).orElse(null);
        User receiver = userRepo.findById((long) receiverId).orElse(null);

        if (requester != null && receiver != null) {
            notificationService.sendMeetupRequestNotification(
                    receiver.getFcmToken(),
                    requester.getName()
            );
        }

        return saved;
    }

    public List<MeetRequest> getIncoming(int userId) {
        return repo.findByReceiverIdAndStatus(userId, "PENDING");
    }

    // ---------------- RESPOND ----------------

    public MeetRequest respond(int requestId, boolean accepted) {
        MeetRequest req = repo.findById(requestId).orElseThrow();

        req.setStatus(accepted ? "ACCEPTED" : "DECLINED");
        repo.save(req);

        if (accepted) {
            Optional<MeetRequest> reverse =
                    repo.findByRequesterIdAndReceiverId(
                            req.getReceiverId(),
                            req.getRequesterId()
                    );

            if (reverse.isEmpty()) {
                MeetRequest rev =
                        new MeetRequest(
                                req.getReceiverId(),
                                req.getRequesterId(),
                                "ACCEPTED"
                        );

                MeetRequest saved = repo.save(rev);
                saved.setMatchId(req.getMatchId());
                repo.save(saved);
            } else {
                reverse.get().setStatus("ACCEPTED");
                repo.save(reverse.get());
            }
        }

        return req;
    }

    @org.springframework.transaction.annotation.Transactional
    public void clearMeetLocation(int matchId) {
        repo.terminateMatchSession(matchId);
        repo.flush();
    }

    // ---------------- STATUS ----------------

    public String getMatchStatus(int matchId) {
        List<MeetRequest> requests = repo.findByMatchId(matchId);

        if (requests.isEmpty()) return "NOT_FOUND";

        return requests.get(0).getStatus();
    }

    public boolean isMutual(int a, int b) {
        Optional<MeetRequest> reqAB = repo.findByRequesterIdAndReceiverId(a, b);
        Optional<MeetRequest> reqBA = repo.findByRequesterIdAndReceiverId(b, a);

        boolean aAccepted = reqAB.isPresent() &&
                "ACCEPTED".equals(reqAB.get().getStatus());

        boolean bAccepted = reqBA.isPresent() &&
                "ACCEPTED".equals(reqBA.get().getStatus());

        return aAccepted && bAccepted;
    }

    // ---------------- MUTUAL LOOKUP ----------------

    public Map<String, Integer> findMutualForUser(int userId) {

        List<MeetRequest> sent =
                repo.findByRequesterIdAndStatus(userId, "ACCEPTED");

        for (MeetRequest s : sent) {
            Optional<MeetRequest> other =
                    repo.findByRequesterIdAndReceiverId(
                            s.getReceiverId(),
                            userId
                    );

            if (other.isPresent() &&
                    "ACCEPTED".equals(other.get().getStatus())) {

                return Map.of(
                        "matchId", s.getMatchId(),
                        "otherUserId", s.getReceiverId()
                );
            }
        }

        List<MeetRequest> received =
                repo.findByReceiverIdAndStatus(userId, "ACCEPTED");

        for (MeetRequest r : received) {
            Optional<MeetRequest> other =
                    repo.findByRequesterIdAndReceiverId(
                            r.getRequesterId(),
                            userId
                    );

            if (other.isPresent() &&
                    "ACCEPTED".equals(other.get().getStatus())) {

                return Map.of(
                        "matchId", r.getMatchId(),
                        "otherUserId", r.getRequesterId()
                );
            }
        }

        return null;
    }

    // ---------------- MIDPOINT ----------------

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

    // ---------------- OVERPASS REPLACEMENT ----------------

    public Map<String, Object> getSuggestions(double lat, double lon) {
        SuggestionsResponse response =
                overpassPlacesService.findNearbyPlaces(lat, lon, 1500);

        return Map.of("results", response.results());
    }

    public Map<String, Object> getSuggestionsByQuery(double lat, double lon, String query) {
        SuggestionsResponse response =
                overpassPlacesService.findPlacesForInterests(
                        lat,
                        lon,
                        1500,
                        List.of(query)
                );

        return Map.of("results", response.results());
    }

    // ---------------- INTERESTS ----------------

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

        return categoriesA.stream()
                .filter(categoriesB::contains)
                .distinct()
                .toList();
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

        Map<String, Object> interestResults =
                getSuggestionsByQuery(lat, lon, query);

        List results = (List) interestResults.get("results");

        if (results == null || results.isEmpty()) {
            return getSuggestions(lat, lon);
        }

        return interestResults;
    }

    // ---------------- CATEGORY MAP (UNCHANGED LOGIC) ----------------

    private String mapCategoryToQuery(String category) {
        return switch (category.toLowerCase()) {
            case "coffee" -> "coffeetasting";
            case "food", "restaurant", "foodie" -> "foodtours";
            case "gym", "fitness" -> "gym";
            case "park", "hiking", "outdoors" -> "running";
            case "library", "studying" -> "reading";
            case "bookstore", "anime" -> "reading";
            case "music", "concert" -> "livemusic";
            case "cinema", "movies" -> "movienights";
            case "bowling" -> "bowling";
            default -> "foodtours";
        };
    }
}