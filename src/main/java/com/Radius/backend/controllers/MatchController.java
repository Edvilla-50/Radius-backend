package com.Radius.backend.controllers;

import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Services.MatchService;
import com.Radius.backend.Services.MeetService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/match")
public class MatchController {

    private final MatchService service;
    private final MeetService meetService;

    public MatchController(MatchService service, MeetService meetService) {
        this.service = service;
        this.meetService = meetService;
    }

    @GetMapping("/{id}")
    public List<User> getMatches(@PathVariable long id) {
        return service.findMyBestMatch(id);
    }

    @PostMapping("/meet/request")
    public ResponseEntity<?> sendMeetRequest(@RequestBody Map<String, Object> body) {
        int userId = ((Number) body.get("userId")).intValue();
        int otherUserId = ((Number) body.get("matchId")).intValue();

        meetService.createRequest(userId, otherUserId);
        return ResponseEntity.ok("Request sent");
    }

    @GetMapping("/meet/respond")
    public MeetRequest respond(@RequestParam int requestId, @RequestParam boolean accepted) {
        return meetService.respond(requestId, accepted);
    }

    @GetMapping("/meet/mutual/{a}/{b}")
    public boolean checkMutual(@PathVariable int a, @PathVariable int b) {
        return meetService.isMutual(a, b);
    }

    @GetMapping("/meet/midpoint/{a}/{b}")
    public Map<String, Double> midpoint(@PathVariable int a, @PathVariable int b) {
        return meetService.getMidpoint(a, b);
    }

    @GetMapping("/meet/suggestions/{a}/{b}")
    public Map<String, Object> suggestions(@PathVariable int a, @PathVariable int b) {
        Map<String, Double> mid = meetService.getMidpoint(a, b);
        return meetService.getSuggestions(mid.get("lat"), mid.get("lon"));
    }

    @GetMapping("/meet/suggestions/interests/{a}/{b}")
    public ResponseEntity<?> suggestionsByInterest(@PathVariable int a, @PathVariable int b) {
        try {
            return ResponseEntity.ok(meetService.getSuggestionsForUsers(a, b));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/meet/incoming/{userId}")
    public List<MeetRequest> getIncoming(@PathVariable int userId) {
        return meetService.getIncoming(userId);
    }

    @GetMapping("/meet/mutual/find/{userId}")
    public ResponseEntity<Map<String, Integer>> getMutualForUser(@PathVariable int userId) {
        Map<String, Integer> result = meetService.findMutualForUser(userId);
        if (result == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(result);
    }

    // MATCHES FLUTTER: ApiService.clearMeetLocation
    @PostMapping("/meet/clearLocation")
    public ResponseEntity<?> clearMeetLocation(@RequestBody Map<String, Integer> payload) {
        Integer matchId = payload.get("matchId");
        if (matchId == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing matchId"));
        }
        
        meetService.clearMeetLocation(matchId);
        return ResponseEntity.ok(Map.of("success", true, "message", "Match session terminated."));
    }

    // MATCHES FLUTTER: ApiService.checkMutual(matchId)
    // This allows the other user's app loop to see the "CANCELLED" status and instantly return home!
    @GetMapping("/meet/location/mutual/{matchId}")
    public ResponseEntity<?> getMatchSessionStatus(@PathVariable int matchId) {
        String status = meetService.getMatchStatus(matchId);
        boolean isCancelled = "CANCELLED".equals(status);
        
        // Return JSON format expected by both Map and Suggestion screens
        return ResponseEntity.ok(Map.of(
            "mutual", !"CANCELLED".equals(status) && !"DECLINED".equals(status),
            "expired", isCancelled,
            "sosTriggered", isCancelled
        ));
    }
}