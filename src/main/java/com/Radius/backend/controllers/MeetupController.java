package com.Radius.backend.controllers;

import com.Radius.backend.Services.OverpassPlacesService;
import com.Radius.backend.dto.SuggestionsResponse;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/meetup")
public class MeetupController {

    private final OverpassPlacesService overpassService;

    public MeetupController(OverpassPlacesService overpassService) {
        this.overpassService = overpassService;
    }

    @GetMapping("/places")
    public SuggestionsResponse getNearbyPlaces(
            @RequestParam double lat,
            @RequestParam double lon
    ) {
        return overpassService.findNearbyPlaces(lat, lon, 1500);
    }
}