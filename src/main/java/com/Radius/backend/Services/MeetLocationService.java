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

    public MeetLocation chooseLocation(int matchId, int chooserId,
            String locationId, String name,
            String address, Double lat, Double lon) {
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) repo.delete(existing);
        MeetLocation loc = new MeetLocation(matchId, chooserId, locationId,
                name, address, lat, lon);
        loc.setAcceptedByA(true);
        loc.setAcceptedByB(false);
        return repo.save(loc);
    }

    public Map<String, Object> getLocation(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);
        Map<String, Object> result = new HashMap<>();
        
        // FIX: If no location is selected yet, it is NOT expired.
        if (loc == null) {
            result.put("expired", false);
            result.put("hasSelection", false); // Helpful extra flag for Flutter
            return result;
        }
        
        if (loc.isCancelled()) {
            result.put("expired", true);
            return result;
        }
        
        boolean expired = loc.getCreatedAt().isBefore(
                Instant.now().minus(1, ChronoUnit.HOURS));
        if (expired) {
            result.put("expired", true);
            return result;
        }
        
        result.put("expired",      false);
        result.put("hasSelection", true);
        result.put("chooserId",   loc.getChooserId());
        result.put("name",        loc.getName()    != null ? loc.getName()    : "");
        result.put("address",     loc.getAddress() != null ? loc.getAddress() : "");
        result.put("lat",         loc.getLat());
        result.put("lon",         loc.getLon());
        result.put("acceptedByA", loc.isAcceptedByA());
        result.put("acceptedByB", loc.isAcceptedByB());
        return result;
    }

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

    public Map<String, Object> checkMutual(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);
        Map<String, Object> result = new HashMap<>();
        if (loc == null) {
            result.put("expired", false);
            result.put("mutual", false);
            return result;
        }

        if (loc.isCancelled()) {
            result.put("expired", true);
            result.put("mutual", false);
            result.put("sosTriggered", true);
            return result;
        }

        boolean expired = loc.getCreatedAt().isBefore(
                Instant.now().minus(1, ChronoUnit.HOURS));
        if (expired) {
            result.put("expired", true);
            return result;
        }
        boolean mutual = loc.isAcceptedByA() && loc.isAcceptedByB();
        result.put("expired",  false);
        result.put("mutual",   mutual);
        result.put("name",     loc.getName()    != null ? loc.getName()    : "");
        result.put("address",  loc.getAddress() != null ? loc.getAddress() : "");
        result.put("lat",      loc.getLat());
        result.put("lon",      loc.getLon());
        return result;
    }

    public void clearLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) repo.delete(existing);
    }

    public void cancelLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) {
            existing.setCancelled(true);
            repo.save(existing);
        }
    }
}