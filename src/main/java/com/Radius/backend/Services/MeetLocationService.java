package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Entity.MeetLocation;
import com.Radius.backend.Entity.MeetRequest;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

@Service
public class MeetLocationService {

    private static final Set<String> ACTIVE_STATUSES = Set.of("PENDING", "ACCEPTED");

    private final MeetLocationRepository repo;
    private final MeetRequestRepository meetRequestRepo;

    public MeetLocationService(
            MeetLocationRepository repo,
            MeetRequestRepository meetRequestRepo) {
        this.repo = repo;
        this.meetRequestRepo = meetRequestRepo;
    }

    // ------------------------------------------------------------------
    // helpers
    // ------------------------------------------------------------------

    private static ResponseStatusException err(HttpStatus status, String msg) {
        return new ResponseStatusException(status, msg);
    }

    // The matchId IS the id of the original request row (MeetService.createRequest
    // sets matchId = id), and the reverse row created on accept shares that matchId.
    // So look the request up by primary key: findByMatchId() would return both rows
    // in no guaranteed order, and the "requester" would flip depending on which came first.
    private MeetRequest requireActiveRequest(int matchId) {
        MeetRequest request = meetRequestRepo.findById(matchId)
                .orElseThrow(() -> err(HttpStatus.NOT_FOUND, "Meetup request not found."));

        String status = request.getStatus() == null ? "" : request.getStatus().toUpperCase();
        if (!ACTIVE_STATUSES.contains(status)) {
            throw err(HttpStatus.GONE, "This meetup is no longer active.");
        }
        return request;
    }

    private static void requireParticipant(MeetRequest request, int userId) {
        if (userId != request.getRequesterId() && userId != request.getReceiverId()) {
            throw err(HttpStatus.FORBIDDEN, "You are not a participant in this meetup request.");
        }
    }

    private static void requireLive(MeetLocation loc) {
        if (loc.isCancelled() || loc.isExpired()) {
            throw err(HttpStatus.GONE, "This meetup has expired or been cancelled.");
        }
    }

    private static String clean(String value, String field, int max, boolean required) {
        String t = value == null ? "" : value.trim();
        if (required && t.isEmpty()) {
            throw err(HttpStatus.BAD_REQUEST, field + " is required.");
        }
        if (t.length() > max) {
            throw err(HttpStatus.BAD_REQUEST, field + " is too long.");
        }
        return t.isEmpty() ? null : t;
    }

    private static void checkCoords(Double lat, Double lon) {
        if (lat != null && (lat.isNaN() || lat < -90 || lat > 90)) {
            throw err(HttpStatus.BAD_REQUEST, "Invalid latitude.");
        }
        if (lon != null && (lon.isNaN() || lon < -180 || lon > 180)) {
            throw err(HttpStatus.BAD_REQUEST, "Invalid longitude.");
        }
    }

    private static String iso(MeetLocation loc) {
        return loc.getExpiresAt().truncatedTo(ChronoUnit.MILLIS).toString();
    }

    // ------------------------------------------------------------------
    // session clock
    // ------------------------------------------------------------------

    // Call from MeetService.respond() when a request is accepted. Creates the
    // place-less row that carries the 1-hour session clock, so expiry is enforced
    // by the server even if nobody ever picks a place or the app is killed.
    @Transactional
    public void startSession(int matchId) {
        if (repo.findByMatchId(matchId) == null) {
            repo.save(new MeetLocation(matchId, 0, null, null, null, null, null));
        }
    }

    // ------------------------------------------------------------------
    // choose / accept / reset
    // ------------------------------------------------------------------

    @Transactional
    public MeetLocation chooseLocation(
            int matchId,
            int userId,
            String locationId,
            String name,
            String address,
            Double lat,
            Double lon) {

        String cleanLocationId = clean(locationId, "locationId", 128, true);
        String cleanName = clean(name, "name", 200, true);
        String cleanAddress = clean(address, "address", 300, false);
        checkCoords(lat, lon);

        MeetRequest request = requireActiveRequest(matchId);

        // Only the person who sent the meetup request can choose the place.
        if (request.getRequesterId() != userId) {
            throw err(HttpStatus.FORBIDDEN,
                    "Only the person who sent the meetup request can select a location.");
        }

        MeetLocation loc = repo.findByMatchId(matchId);

        if (loc == null) {
            loc = new MeetLocation(matchId, userId, cleanLocationId, cleanName, cleanAddress, lat, lon);
        } else {
            requireLive(loc);
            if (loc.isAcceptedByA() && loc.isAcceptedByB()) {
                throw err(HttpStatus.CONFLICT, "The meetup place is already confirmed.");
            }
            // Same row, same clock: changing the place does not buy another hour.
            loc.setPlace(userId, cleanLocationId, cleanName, cleanAddress, lat, lon);
        }

        loc.setAcceptedByA(true);   // the chooser implicitly accepts their own pick
        loc.setAcceptedByB(false);
        loc.setCancelled(false);

        return repo.save(loc);
    }

    @Transactional
    public MeetLocation acceptLocation(int matchId, int userId, String locationId) {
        MeetRequest request = requireActiveRequest(matchId);
        requireParticipant(request, userId);

        MeetLocation loc = repo.findByMatchId(matchId);
        if (loc == null || !loc.hasPlace()) {
            throw err(HttpStatus.CONFLICT, "No meetup location has been selected.");
        }
        requireLive(loc);

        // The user must accept the place they were actually shown. If the sender
        // swapped it in the meantime, reject so the client re-reads and re-prompts.
        if (locationId != null && !locationId.isBlank()
                && !locationId.equals(loc.getLocationId())) {
            throw err(HttpStatus.CONFLICT, "The meetup place changed. Please review it again.");
        }

        if (userId == loc.getChooserId()) {
            loc.setAcceptedByA(true);
        } else {
            loc.setAcceptedByB(true);
        }

        return repo.save(loc);
    }

    // "Pick another" (recipient) and "Change place" (sender). Clears only the
    // place and both accept flags. The match stays alive and the clock keeps running.
    @Transactional
    public void resetLocation(int matchId, int userId) {
        MeetRequest request = requireActiveRequest(matchId);
        requireParticipant(request, userId);

        MeetLocation loc = repo.findByMatchId(matchId);
        if (loc == null) {
            return; // nothing selected, nothing to reset
        }
        requireLive(loc);

        if (loc.isAcceptedByA() && loc.isAcceptedByB()) {
            throw err(HttpStatus.CONFLICT, "The meetup place is already confirmed.");
        }

        loc.clearPlace();
        repo.save(loc);
    }

    // ------------------------------------------------------------------
    // polling endpoints
    // ------------------------------------------------------------------

    public Map<String, Object> getLocation(int matchId) {
        MeetLocation loc = repo.findByMatchId(matchId);
        Map<String, Object> result = new HashMap<>();

        if (loc == null) {
            result.put("expired", false);
            result.put("hasSelection", false);
            return result;
        }

        if (loc.isCancelled() || loc.isExpired()) {
            result.put("expired", true);
            result.put("hasSelection", false);
            return result;
        }

        result.put("expired", false);
        result.put("expiresAt", iso(loc));

        if (!loc.hasPlace()) {
            result.put("hasSelection", false);
            return result;
        }

        result.put("hasSelection", true);
        result.put("chooserId", loc.getChooserId());
        result.put("locationId", loc.getLocationId() != null ? loc.getLocationId() : "");
        result.put("name", loc.getName() != null ? loc.getName() : "");
        result.put("address", loc.getAddress() != null ? loc.getAddress() : "");
        result.put("lat", loc.getLat());
        result.put("lon", loc.getLon());
        result.put("acceptedByA", loc.isAcceptedByA());
        result.put("acceptedByB", loc.isAcceptedByB());

        return result;
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

        if (loc.isExpired()) {
            result.put("expired", true);
            result.put("mutual", false);
            result.put("sosTriggered", false);
            return result;
        }

        boolean mutual = loc.hasPlace() && loc.isAcceptedByA() && loc.isAcceptedByB();

        result.put("expired", false);
        result.put("sosTriggered", false);
        result.put("mutual", mutual);
        result.put("name", loc.getName() != null ? loc.getName() : "");
        result.put("address", loc.getAddress() != null ? loc.getAddress() : "");
        result.put("lat", loc.getLat());
        result.put("lon", loc.getLon());

        return result;
    }

    // ------------------------------------------------------------------
    // cancel (SOS / client-side expiry)
    // ------------------------------------------------------------------

    @Transactional
    public void cancelLocation(int matchId) {
        MeetLocation existing = repo.findByMatchId(matchId);

        if (existing != null) {
            existing.setCancelled(true);
            repo.save(existing);
        }
    }
}