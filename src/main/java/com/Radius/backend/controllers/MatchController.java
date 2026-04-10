package com.Radius.backend.controllers;

import com.Radius.backend.Entity.User;
import com.Radius.backend.Services.MatchService;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/match")
public class MatchController {

    private final MatchService service;

    public MatchController(MatchService service){
        this.service = service;
    }

    @GetMapping("/{id}")
    public List<User> getMatches(@PathVariable long id){
        return service.findMyBestMatch(id);
    }
}