package com.Radius.backend.controllers;

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

        meetService.sendMeetRequest(userId,matchId);
        return ResponseEntity.ok("Request sent");
    }
}