package com.Radius.backend.controllers;

import com.Radius.backend.Bases.InterestRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.LocationUpdate;
import com.Radius.backend.Entity.User;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.web.bind.annotation.*;

import com.Radius.backend.Entity.InterestEntity;
import java.util.Map;

@RestController
@RequestMapping("/user")
public class UserController {

    private final InterestRepository interestRepository;
    private final UserRepository repo;

    public UserController(UserRepository repo, InterestRepository interestRepository){
        this.repo = repo;
        this.interestRepository = interestRepository;
    }

    @PostMapping("/{id}/location")
    public User updateLocation(@PathVariable long id, @RequestBody LocationUpdate location){
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        user.setLat(location.getLat());
        user.setLon(location.getLon());
        return repo.save(user);
    }

    @PostMapping
    public User createUser(@RequestBody User user){
        return repo.save(user);
    }
    @PutMapping("/{id}/interests")
    public User updateInterests(@PathVariable long id, @RequestBody List<Long> interestIds){
        User user = repo.findById(id)
            .orElseThrow(()-> new RuntimeException("User not found "+ id));
        user.getInterests().clear();
        repo.save(user);
        
            List<InterestEntity> ordered = interestIds.stream()
            .map(iid -> interestRepository.findById(iid)
                .orElseThrow(() -> new RuntimeException("Interest not found: "+ iid)))
            .collect(Collectors.toList());
        user.setInterests(ordered);
        return repo.save(user);
    }
    @GetMapping("/{id}")
    public User getUser(@PathVariable long id){
        return repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
    }  
    @GetMapping("/interests/all")
    public List<InterestEntity> getAllInterests(){
        return interestRepository.findAll();
    }
    @PutMapping("/{id}/profile-html")
    public User updateProfileHtml(@PathVariable long id, @RequestBody Map<String, String> body){
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        user.setHtmlProfile(body.get("html"));
        return repo.save(user);
    }
}