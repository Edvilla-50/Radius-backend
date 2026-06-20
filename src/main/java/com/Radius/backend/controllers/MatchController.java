package com.Radius.backend.controllers;

import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Services.MatchService;
import com.Radius.backend.Services.MeetService;
import com.Radius.backend.Services.MeetLocationService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/match")
public class MatchController {

    private final MatchService service;
    private final MeetService meetService;
    private final MeetLocationService meetLocationService;

    public MatchController(MatchService service, MeetService meetService, MeetLocationService meetLocationService) {
        this.service = service;
        this.meetService = meetService;
        this.meetLocationService = meetLocationService;
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

    @GetMapping("/meet/suggestions/interests/{a}/{b}/{matchId}")
    public ResponseEntity<?> suggestionsByInterest(
            @PathVariable int a,
            @PathVariable int b,
            @PathVariable int matchId) {

        try {
            return ResponseEntity.ok(
                    meetService.getSuggestionsForMatch(a, b, matchId)
            );
        } catch (Exception e) {
            return ResponseEntity.status(500)
                    .body(Map.of("error", e.getMessage()));
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
    // FIXED: Also marks the MeetLocation row as cancelled (via
    // MeetLocationService.cancelLocation) instead of leaving it untouched.
    // The OTHER user's polling loop calls GET /meet/location/mutual/{matchId}
    // (MeetLocationController/MeetLocationService.checkMutual), which now
    // checks this cancelled flag and reports expired:true/sosTriggered:true.
    // Previously this endpoint only cancelled the MeetRequest rows, leaving
    // the separate MeetLocation row untouched, so the side that didn't
    // trigger SOS never received any cancellation signal and stayed stuck.
    @PostMapping("/meet/clearLocation")
    public ResponseEntity<?> clearMeetLocation(@RequestBody Map<String, Integer> payload) {
        Integer matchId = payload.get("matchId");
        if (matchId == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Missing matchId"));
        }

        meetService.clearMeetLocation(matchId);
        meetLocationService.cancelLocation(matchId);
        return ResponseEntity.ok(Map.of("success", true, "message", "Match session terminated."));
    }

    // MATCHES FLUTTER: ApiService.checkMutual(matchId)
    // This allows the other user's app loop to see the "CANCELLED" status and instantly return home!
    @GetMapping("/meet/location/mutual/{matchId}")
    public ResponseEntity<?> getMatchSessionStatus(@PathVariable int matchId) {
        String status = meetService.getMatchStatus(matchId);
        
        // 🌟 FIX: If there are no requests found, return safe defaults instead of let-through flags!
        if (status == null || "NOT_FOUND".equals(status)) {
            return ResponseEntity.ok(Map.of(
                "mutual", false,
                "expired", false,
                "sosTriggered", false
            ));
        }

        boolean isCancelled = "CANCELLED".equals(status);
        
        // Return JSON format expected by both Map and Suggestion screens
        return ResponseEntity.ok(Map.of(
            "mutual", !"CANCELLED".equals(status) && !"DECLINED".equals(status),
            "expired", isCancelled,
            "sosTriggered", isCancelled
        ));
    }
    @GetMapping("/meet/suggestions/sync/{matchId}/{a}/{b}")
    public Map<String, Object> syncedSuggestions(
            @PathVariable int matchId,
            @PathVariable int a,
            @PathVariable int b
    ) {
    return meetService.getOrCreateSuggestions(a, b, matchId);
    }
}