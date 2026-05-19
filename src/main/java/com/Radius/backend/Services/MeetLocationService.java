package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Entity.MeetLocation;
import org.springframework.stereotype.Service;

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
        loc.setAcceptedByA(true);  // chooser always accepts their own pick
        loc.setAcceptedByB(false);

        return repo.save(loc);
    }

    // Get current location selection
    public MeetLocation getLocation(int matchId) {
        return repo.findByMatchId(matchId);
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

    // Check if both users accepted.
    // Uses HashMap (not Map.of) so null name/address don't throw NPE.
    public Map<String, Object> checkMutual(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);

        Map<String, Object> result = new HashMap<>();

        if (loc == null) {
            result.put("mutual", false);
            return result;
        }

        boolean mutual = loc.isAcceptedByA() && loc.isAcceptedByB();
        result.put("mutual", mutual);
        result.put("name",    loc.getName()    != null ? loc.getName()    : "");
        result.put("address", loc.getAddress() != null ? loc.getAddress() : "");
        return result;
    }

    // Called by the Flutter client AFTER both sides have navigated away.
    public void clearLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) {
            repo.delete(existing);
        }
    }
}