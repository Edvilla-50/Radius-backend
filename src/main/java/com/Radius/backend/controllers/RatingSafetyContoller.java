package com.Radius.backend.controllers;
import com.Radius.backend.Entity.SafetyRating;
import com.Radius.backend.Services.SafetyRatingService;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
@RestController
@RequestMapping("/safety")
@CrossOrigin(origins = "*")
public class RatingSafetyContoller {
    private final SafetyRatingService service;

    public RatingSafetyContoller(SafetyRatingService service){
        this.service = service;
    }

    @PostMapping("/rate")
    public SafetyRating rateLocation(@RequestBody Map<String, Object> body){
        String locationId = (String) body.get("locationId");
        int userId = (int) body.get("userId");
        boolean wellLit = (boolean) body.get("wellLit");
        boolean atmosphere = (boolean) body.get("atmosphere");

        return service.rateLocation(locationId, userId, wellLit, wellLit, atmosphere);
    }
    @GetMapping("/score/{locationId}")
    public Map<String, Object> getScore(@PathVariable String locationId){
        return service.getSafetyScore(locationId);
    }
}
