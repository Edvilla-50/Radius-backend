package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Entity.MeetLocation;
import org.springframework.stereotype.Service;

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

        // Whoever accepts and isn't the chooser is "B"
        if (userId == loc.getChooserId()) {
            loc.setAcceptedByA(true);
        } else {
            loc.setAcceptedByB(true);
        }

        return repo.save(loc);
    }

    // Check if both users accepted
    public Map<String, Object> checkMutual(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);
        if (loc == null) return Map.of("mutual", false);

        boolean mutual = loc.isAcceptedByA() && loc.isAcceptedByB();

        return Map.of(
                "mutual", mutual,
                "name", loc.getName(),
                "address", loc.getAddress()
        );
    }
}
