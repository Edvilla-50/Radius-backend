package com.Radius.backend.controllers;

import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.LocationUpdate;
import com.Radius.backend.Entity.User;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/user")
public class UserController {

    private final UserRepository repo;

    public UserController(UserRepository repo){
        this.repo = repo;
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
}