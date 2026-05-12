package com.Radius.backend.controllers;

import com.Radius.backend.Entity.MeetLocation;
import com.Radius.backend.Services.MeetLocationService;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/meet")
@CrossOrigin(origins = "*")
public class MeetLocationController {

    private final MeetLocationService service;

    public MeetLocationController(MeetLocationService service) {
        this.service = service;
    }

    @PostMapping("/select-location")
    public MeetLocation selectLocation(@RequestBody Map<String, Object> body) {
        int matchId = (int) body.get("matchId");
        int userId = (int) body.get("userId");
        String locationId = (String) body.get("locationId");
        String name = (String) body.get("name");
        String address = (String) body.get("address");

        return service.chooseLocation(matchId, userId, locationId, name, address);
    }

    @GetMapping("/location/{matchId}")
    public MeetLocation getLocation(@PathVariable int matchId) {
        return service.getLocation(matchId);
    }
}
