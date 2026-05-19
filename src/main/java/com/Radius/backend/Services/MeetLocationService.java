package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Entity.MeetLocation;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;

@Service
public class MeetLocationService {

    private final MeetLocationRepository repo;

    public MeetLocationService(MeetLocationRepository repo) {
        this.repo = repo;
    }

    // User selects a location
    public MeetLocation chooseLocation(int matchId, int chooserId,
                                       String locationId, String name, String address) {

        // Remove old selection if it exists
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) {
            repo.delete(existing);
        }

        MeetLocation loc = new MeetLocation(matchId, chooserId, locationId, name, address);
        loc.setAcceptedByA(true);   // chooser always accepts their own pick
        loc.setAcceptedByB(false);

        return repo.save(loc);
    }

    // Get current location selection (NOW RETURNS EXPIRED FLAG)
    public Map<String, Object> getLocation(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);

        Map<String, Object> result = new HashMap<>();

        if (loc == null) {
            result.put("expired", true);
            return result;
        }

        // Check expiration (1 hour)
        boolean expired = loc.getCreatedAt().isBefore(
                Instant.now().minus(1, ChronoUnit.HOURS)
        );

        if (expired) {
            result.put("expired", true);
            return result;
        }

        // Not expired → return normal data
        result.put("expired", false);
        result.put("chooserId", loc.getChooserId());
        result.put("name", loc.getName());
        result.put("address", loc.getAddress());
        result.put("acceptedByA", loc.isAcceptedByA());
        result.put("acceptedByB", loc.isAcceptedByB());

        return result;
    }

    // Other user accepts the location
    public MeetLocation acceptLocation(int matchId, int userId) {
        MeetLocation loc = repo.findByMatchId(matchId);
        if (loc == null) return null;

        if (userId == loc.getChooserId()) {
            loc.setAcceptedByA(true);
        } else {
            loc.setAcceptedByB(true);
        }

        return repo.save(loc);
    }

    // Check if both users accepted (NOW RETURNS EXPIRED FLAG)
    public Map<String, Object> checkMutual(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);

        Map<String, Object> result = new HashMap<>();

        if (loc == null) {
            result.put("expired", true);
            return result;
        }

        boolean expired = loc.getCreatedAt().isBefore(
                Instant.now().minus(1, ChronoUnit.HOURS)
        );

        if (expired) {
            result.put("expired", true);
            return result;
        }

        boolean mutual = loc.isAcceptedByA() && loc.isAcceptedByB();

        result.put("expired", false);
        result.put("mutual", mutual);
        result.put("name", loc.getName() != null ? loc.getName() : "");
        result.put("address", loc.getAddress() != null ? loc.getAddress() : "");

        return result;
    }

    // Called by Flutter AFTER both sides navigate away
    public void clearLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) {
            repo.delete(existing);
        }
    }
}
