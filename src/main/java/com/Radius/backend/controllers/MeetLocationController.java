package com.Radius.backend.controllers;

import com.Radius.backend.Services.MeetLocationService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.Map;

// No @CrossOrigin: the Flutter app is not a browser. No per-poll logging: the app
// polls every 3 seconds per phone and the old println calls flooded the logs.
@RestController
@RequestMapping("/meet")
public class MeetLocationController {

    private final MeetLocationService service;

    public MeetLocationController(MeetLocationService service) {
        this.service = service;
    }

    record SelectRequest(Integer matchId, Integer userId, String locationId,
                         String name, String address, Double lat, Double lon) {}

    record AcceptRequest(Integer matchId, Integer userId, String locationId) {}

    record ResetRequest(Integer matchId, Integer userId) {}

    private static int need(Integer value, String field) {
        if (value == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, field + " is required.");
        }
        return value;
    }

    // TODO(auth): take userId from the verified token instead of the body.
    @PostMapping("/select-location")
    public Map<String, Object> selectLocation(@RequestBody SelectRequest body) {
        int matchId = need(body.matchId(), "matchId");
        service.chooseLocation(matchId, need(body.userId(), "userId"),
                body.locationId(), body.name(), body.address(), body.lat(), body.lon());
        return service.getLocation(matchId);
    }

    @PostMapping("/location/accept")
    public Map<String, Object> accept(@RequestBody AcceptRequest body) {
        int matchId = need(body.matchId(), "matchId");
        service.acceptLocation(matchId, need(body.userId(), "userId"), body.locationId());
        return service.getLocation(matchId);
    }

    @PostMapping("/location/reset")
    public Map<String, Object> reset(@RequestBody ResetRequest body) {
        int matchId = need(body.matchId(), "matchId");
        service.resetLocation(matchId, need(body.userId(), "userId"));
        return service.getLocation(matchId);
    }

    // TODO(auth): both GETs below return the chosen place; once tokens exist,
    // only the two participants of the match may read them.
    @GetMapping("/location/{matchId}")
    public Map<String, Object> getLocation(@PathVariable int matchId) {
        return service.getLocation(matchId);
    }

    @GetMapping("/location/mutual/{matchId}")
    public Map<String, Object> mutual(@PathVariable int matchId) {
        return service.checkMutual(matchId);
    }

    // The old DELETE /meet/location/{matchId} is removed: it let anyone clear any
    // match's location. Cancelling goes through POST /match/meet/clearLocation,
    // resetting through POST /meet/location/reset.
}