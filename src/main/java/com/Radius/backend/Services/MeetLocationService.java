
package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Entity.MeetLocation;
import com.Radius.backend.Entity.MeetRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;

@Service
public class MeetLocationService {

    private final MeetLocationRepository repo;
    private final MeetRequestRepository meetRequestRepo;

    public MeetLocationService(
            MeetLocationRepository repo,
            MeetRequestRepository meetRequestRepo) {
        this.repo = repo;
        this.meetRequestRepo = meetRequestRepo;
    }

    @Transactional
    public MeetLocation chooseLocation(
            int matchId,
            int chooserId,
            String locationId,
            String name,
            String address,
            Double lat,
            Double lon) {

        // Only the original requester can select a meetup location.
        MeetRequest request = meetRequestRepo.findByMatchId(matchId)
        .stream()
        .filter(r -> "PENDING".equalsIgnoreCase(r.getStatus())
                  || "ACCEPTED".equalsIgnoreCase(r.getStatus()))
        .findFirst()
        .orElse(null);

        if (request == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Meetup request not found."
            );
        }

        if (request.getRequesterId() != chooserId) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Only the person who sent the meetup request can select a location."
            );
        }

        // Replace any previous selection only after authorization succeeds.
        MeetLocation existing = repo.findByMatchId(matchId);

        if (existing != null) {
            repo.delete(existing);
            repo.flush();
        }

        MeetLocation loc = new MeetLocation(
                matchId,
                chooserId,
                locationId,
                name,
                address,
                lat,
                lon
        );

        loc.setAcceptedByA(true);
        loc.setAcceptedByB(false);
        loc.setCancelled(false);

        return repo.save(loc);
    }

    public Map<String, Object> getLocation(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);
        Map<String, Object> result = new HashMap<>();

        if (loc == null) {
            result.put("expired", false);
            result.put("hasSelection", false);
            return result;
        }

        if (loc.isCancelled()) {
            result.put("expired", true);
            result.put("hasSelection", false);
            return result;
        }

        boolean expired = loc.getCreatedAt().isBefore(
                Instant.now().minus(1, ChronoUnit.HOURS)
        );

        if (expired) {
            result.put("expired", true);
            result.put("hasSelection", false);
            return result;
        }

        result.put("expired", false);
        result.put("hasSelection", true);
        result.put("chooserId", loc.getChooserId());
        result.put("name", loc.getName() != null ? loc.getName() : "");
        result.put("address", loc.getAddress() != null ? loc.getAddress() : "");
        result.put("lat", loc.getLat());
        result.put("lon", loc.getLon());
        result.put("acceptedByA", loc.isAcceptedByA());
        result.put("acceptedByB", loc.isAcceptedByB());

        return result;
    }

    @Transactional
    public MeetLocation acceptLocation(int matchId, int userId) {
        MeetLocation loc = repo.findByMatchId(matchId);

        if (loc == null) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "No meetup location has been selected."
            );
        }

        if (loc.isCancelled()
                || loc.getCreatedAt().isBefore(
                        Instant.now().minus(1, ChronoUnit.HOURS))) {
            throw new ResponseStatusException(
                    HttpStatus.GONE,
                    "This meetup location has expired or been cancelled."
            );
        }

        // Verify the user belongs to this meetup request.
        MeetRequest request = meetRequestRepo.findByMatchId(matchId)
        .stream()
        .filter(r -> "PENDING".equalsIgnoreCase(r.getStatus())
                  || "ACCEPTED".equalsIgnoreCase(r.getStatus()))
        .findFirst()
        .orElse(null);

        if (request == null
                || (userId != request.getRequesterId()
                && userId != request.getReceiverId())) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "You are not a participant in this meetup request."
            );
        }

        // The chooser has already accepted their own selection.
        // Only the other participant can accept it.
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
            result.put("sosTriggered", false);
            return result;
        }

        if (loc.isCancelled()) {
            result.put("expired", true);
            result.put("mutual", false);
            result.put("sosTriggered", true);
            return result;
        }

        boolean expired = loc.getCreatedAt().isBefore(
                Instant.now().minus(1, ChronoUnit.HOURS)
        );

        if (expired) {
            result.put("expired", true);
            result.put("mutual", false);
            result.put("sosTriggered", false);
            return result;
        }

        boolean mutual = loc.isAcceptedByA() && loc.isAcceptedByB();

        result.put("expired", false);
        result.put("sosTriggered", false);
        result.put("mutual", mutual);
        result.put("name", loc.getName() != null ? loc.getName() : "");
        result.put("address", loc.getAddress() != null ? loc.getAddress() : "");
        result.put("lat", loc.getLat());
        result.put("lon", loc.getLon());

        return result;
    }

    @Transactional
    public void clearLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);

        if (existing != null) {
            repo.delete(existing);
        }
    }

    @Transactional
    public void cancelLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);

        if (existing != null) {
            existing.setCancelled(true);
            repo.save(existing);
        }
    }
}
