package com.Radius.backend.controllers;

import com.Radius.backend.Services.FourSquareService;
import org.springframework.web.bind.annotation.*;
import java.util.*;

@RestController
@RequestMapping("/meetup")
public class MeetupController {

    private final FourSquareService foursquareService;

    public MeetupController(FourSquareService foursquareService){
        this.foursquareService = foursquareService;
    }

    @GetMapping("/places")
    public List<Map<String, Object>> getNearbyPlaces(
        @RequestParam double lat,
        @RequestParam double lon
    ){
        return foursquareService.getNearbyPlaces(lat, lon);
    }
}