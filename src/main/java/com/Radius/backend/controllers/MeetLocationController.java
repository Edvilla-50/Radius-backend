package com.Radius.backend.controllers;

import com.Radius.backend.Entity.MeetLocation;
import com.Radius.backend.Services.MeetLocationService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/meet")
@CrossOrigin(originPatterns = "*")
public class MeetLocationController {

    private final MeetLocationService service;

    public MeetLocationController(MeetLocationService service) {
        this.service = service;
    }

    @PostMapping("/select-location")
    public MeetLocation selectLocation(@RequestBody Map<String, Object> body) {
        int matchId = ((Number) body.get("matchId")).intValue();
        int userId = ((Number) body.get("userId")).intValue();
        String locationId = (String) body.get("locationId");
        String name = (String) body.get("name");
        String address = (String) body.get("address");
        return service.chooseLocation(matchId, userId, locationId, name, address);
    }

    @PostMapping("/location/accept")
    public MeetLocation accept(@RequestBody Map<String, Object> body) {
        int matchId = ((Number) body.get("matchId")).intValue();
        int userId = ((Number) body.get("userId")).intValue();
        return service.acceptLocation(matchId, userId);
    }

    // mutual MUST be before /{matchId} or Spring grabs "mutual" as the path variable
    @GetMapping("/location/mutual/{matchId}")
    public Map<String, Object> mutual(@PathVariable int matchId) {
        return service.checkMutual(matchId);
    }

    @GetMapping("/location/{matchId}")
    public Map<String, Object> getLocation(@PathVariable int matchId) {
        return service.getLocation(matchId);
    }

    @DeleteMapping("/location/{matchId}")
    public void clearLocation(@PathVariable int matchId) {
        service.clearLocation(matchId);
    }
}
