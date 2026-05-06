package com.Radius.backend.controllers;

import com.Radius.backend.Bases.InterestRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.LocationUpdate;
import com.Radius.backend.Entity.User;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;

import com.Radius.backend.requests.LoginRequest;
import com.Radius.backend.requests.RegisterRequest;
import com.Radius.backend.Entity.InterestEntity;
import java.util.Map;

@RestController
@RequestMapping("/user")
public class UserController {

    private final InterestRepository interestRepository;
    private final UserRepository repo;
    private final BCryptPasswordEncoder encoder;
    public UserController(UserRepository repo,InterestRepository interestRepository,BCryptPasswordEncoder encoder) {
        this.repo = repo;
        this.interestRepository = interestRepository;
        this.encoder = encoder;
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
    @GetMapping(value = "/{id}/profile-html", produces = "application/json")
    public Map<String, String> getProfileHtml(@PathVariable long id) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        return Map.of("html", user.getHtmlProfile());
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {

        if (repo.findByEmail(req.getEmail()).isPresent()) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        User user = new User();
        user.setEmail(req.getEmail());
        user.setPassword(encoder.encode(req.getPassword()));
        user.setName(req.getName());

        repo.save(user);

        return ResponseEntity.ok(Map.of("userId", user.getId()));
    }
    @PostMapping("/login")
    public ResponseEntity<?> login (@RequestBody LoginRequest req){
        User user = repo.findByEmail(req.getEmail())
            .orElseThrow(() -> new RuntimeException("Invalid email"));
        if(!encoder.matches(req.getPassword(), user.getPassword())){
            return ResponseEntity.badRequest().body("Invalid credentials");
        }   

        return ResponseEntity.ok(Map.of(
            "userId", user.getId(),
            "name", user.getName()
        ));
    }

}