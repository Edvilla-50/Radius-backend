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
    public List<User> getMatches(@PathVariable long id){
        return service.findMyBestMatch(id);
    }

    @PostMapping("/meet/request")
    public ResponseEntity<?> sendMeetRequest(@RequestBody Map<String, Object>body){
        int userId = (int) body.get("userId");
        int matchId = (int) body.get ("matchId");

        meetService.createRequest(userId,matchId);
        return ResponseEntity.ok("Request sent");
    }

    @GetMapping("/meet/respond")
    public MeetRequest respond(@RequestParam int requestId, @RequestParam boolean accepted) {
        return meetService.respond(requestId, accepted);
    }
    @GetMapping("/meet/mutual/{a}/{b}")
    public boolean checkMutual(@PathVariable int a, @PathVariable int b){
        return meetService.isMutual(a, b);
    }
    @GetMapping("/meet/midpoint/{a}/{b}")
    public Map<String, Double> midpoint(@PathVariable int a, @PathVariable int b){
        return meetService.getMidpoint(a, b);
    }
    @GetMapping("/meet/suggestions/{a}/{b}")
    public Map<String, Object> suggestions(@PathVariable int a, @PathVariable int b){
        Map<String, Double> mid = meetService.getMidpoint(a, b);
        return meetService.getSuggestions(mid.get("lat"), mid.get("lon"));
    }
    @GetMapping("/meet/suggestions/interests/{a}/{b}")
    public ResponseEntity<?> suggestionsByInterest(@PathVariable int a, @PathVariable int b) {
        try {
            return ResponseEntity.ok(meetService.getSuggestionsForUsers(a, b));
        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(
                Map.of("error", e.getMessage())
            );
        }
    }
    @GetMapping("/meet/incoming/{userId}")
    public List<MeetRequest> getIncoming(@PathVariable int userId) { 
        return meetService.getIncoming(userId);
    }
}