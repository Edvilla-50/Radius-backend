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
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Supplier;

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

    // matchId -> cached suggestions. Only non-empty results are cached, and
    // entries expire so a bad/stale result can't stick around forever.
    private final Map<Integer, Map<String, Object>> suggestionsCache = new ConcurrentHashMap<>();
    private final Map<Integer, Long> suggestionsCachedAt = new ConcurrentHashMap<>();
    private static final long CACHE_TTL_MS = 30 * 60 * 1000L;

    // One lock per match so both phones share one lookup, without blocking other matches.
    private final Map<Integer, Object> suggestionLocks = new ConcurrentHashMap<>();

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

    // ---------------- MUTUAL FIND ----------------

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

    // ---------------- IS MUTUAL ----------------

    public boolean isMutual(int a, int b) {

        Optional<MeetRequest> reqAB =
                repo.findByRequesterIdAndReceiverId(a, b);

        Optional<MeetRequest> reqBA =
                repo.findByRequesterIdAndReceiverId(b, a);

        boolean aAccepted = reqAB.isPresent()
                && "ACCEPTED".equals(reqAB.get().getStatus());

        boolean bAccepted = reqBA.isPresent()
                && "ACCEPTED".equals(reqBA.get().getStatus());

        return aAccepted && bAccepted;
    }

    // ---------------- CLEAR LOCATION ----------------

    @org.springframework.transaction.annotation.Transactional
    public void clearMeetLocation(int matchId) {

        List<MeetRequest> requests = repo.findByMatchId(matchId);

        for (MeetRequest r : requests) {
            r.setStatus("CANCELLED");
            repo.save(r);
        }

        repo.flush();

        suggestionsCache.remove(matchId);
        suggestionsCachedAt.remove(matchId);
        suggestionLocks.remove(matchId);
    }

    // ---------------- MATCH STATUS ----------------

    public String getMatchStatus(int matchId) {

        List<MeetRequest> requests = repo.findByMatchId(matchId);

        if (requests.isEmpty()) return "NOT_FOUND";

        return requests.get(0).getStatus();
    }

    // ---------------- MIDPOINT ----------------

    public Map<String, Double> getMidpoint(int userA, int userB) {

        User a = userRepo.findById((long) userA).orElseThrow();
        User b = userRepo.findById((long) userB).orElseThrow();

        Map<String, Double> map = new HashMap<>();
        map.put("lat", (a.getLat() + b.getLat()) / 2.0);
        map.put("lon", (a.getLon() + b.getLon()) / 2.0);

        return map;
    }

    // ---------------- SYNCED SUGGESTIONS ----------------

    private Map<String, Object> getCachedSuggestions(int matchId) {
        Map<String, Object> cached = suggestionsCache.get(matchId);
        Long at = suggestionsCachedAt.get(matchId);
        if (cached != null && at != null
                && System.currentTimeMillis() - at < CACHE_TTL_MS) {
            return cached;
        }
        return null;
    }

    public Map<String, Object> getSuggestionsForMatch(int userA, int userB, int matchId) {

        // Fast path: already computed for this match.
        Map<String, Object> cached = getCachedSuggestions(matchId);
        if (cached != null) return cached;

        // Both phones for the same match queue up here, so Overpass is only hit once.
        Object lock = suggestionLocks.computeIfAbsent(matchId, k -> new Object());

        synchronized (lock) {
            cached = getCachedSuggestions(matchId);
            if (cached != null) return cached;

            Map<String, Double> mid = getMidpoint(userA, userB);
            double lat = mid.get("lat");
            double lon = mid.get("lon");

            List<String> shared = getSharedCategories(userA, userB);
            Map<String, Object> result;

            if (shared.isEmpty()) {
                result = getSuggestions(lat, lon);
            } else {
                String targetKey = mapCategoryToQuery(shared.get(0));
                List<Map<String, String>> filters =
                        InterestTagMapper.resolveTagFilters(List.of(targetKey));

                if (filters.isEmpty()) {
                    result = getSuggestions(lat, lon);
                } else {
                    result = getSuggestionsByQuery(lat, lon, filters);
                }

                List<?> results = (List<?>) result.get("results");
                if (results == null || results.isEmpty()) {
                    result = getSuggestions(lat, lon);
                }
            }

            List<?> finalResults = (List<?>) result.get("results");
            int count = finalResults == null ? 0 : finalResults.size();
            System.out.println("Suggestions for match " + matchId + ": " + count + " results");

            // Never cache an empty answer, so the next request tries again.
            if (count > 0) {
                suggestionsCache.put(matchId, result);
                suggestionsCachedAt.put(matchId, System.currentTimeMillis());
            }

            return result;
        }
    }

    public Map<String, Object> getOrCreateSuggestions(int userA, int userB, int matchId) {
        return getSuggestionsForMatch(userA, userB, matchId);
    }

    // ---------------- OVERPASS (with retry) ----------------

    // Overpass times out / rate-limits often. Retry, and treat an empty result as a
    // failure too, since the service may swallow errors and return an empty list.
    private Map<String, Object> fetchWithRetry(int maxAttempts, Supplier<Map<String, Object>> call) {
        Map<String, Object> last = Map.of("results", List.of());

        for (int attempt = 1; attempt <= maxAttempts; attempt++) {
            try {
                Map<String, Object> r = call.get();
                List<?> list = (List<?>) r.get("results");
                if (list != null && !list.isEmpty()) return r;
                last = r;
                System.out.println("Overpass attempt " + attempt + " returned no results");
            } catch (RuntimeException e) {
                System.out.println("Overpass attempt " + attempt + " failed: " + e);
            }

            if (attempt < maxAttempts) {
                try {
                    Thread.sleep(1000L * attempt);
                } catch (InterruptedException ie) {
                    Thread.currentThread().interrupt();
                    break;
                }
            }
        }
        return last;
    }

    public Map<String, Object> getSuggestions(double lat, double lon) {
        return fetchWithRetry(3, () -> {
            SuggestionsResponse response = overpassPlacesService.findNearbyPlaces(lat, lon, 1500);
            return Map.<String, Object>of("results", response.results());
        });
    }

    public Map<String, Object> getSuggestionsByQuery(double lat, double lon, List<Map<String, String>> filters) {
        return fetchWithRetry(2, () -> {
            SuggestionsResponse response =
                    overpassPlacesService.findPlacesForInterests(lat, lon, 1500, filters);
            return Map.<String, Object>of("results", response.results());
        });
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

    // ---------------- CATEGORY MAP ----------------

    private String mapCategoryToQuery(String category) {
        return switch (category.toLowerCase().trim()) {
            case "coffee", "coffeetasting" -> "coffeetasting";
            case "food", "restaurant", "foodie" -> "foodtours";
            case "gym", "fitness" -> "gym";
            case "park", "hiking", "outdoors" -> "hiking";
            case "library", "studying" -> "reading";
            case "bookstore", "anime", "boardgames" -> "boardgames";
            case "music", "concert" -> "concert";
            case "cinema", "movies" -> "movienights";
            case "bowling" -> "bowling";
            default -> "foodtours";
        };
    }
}