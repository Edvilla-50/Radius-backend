package com.Radius.backend.controllers;

import com.Radius.backend.Bases.InterestRepository;
import com.Radius.backend.Entity.InterestEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/interests")
public class InterestController {

    private final InterestRepository interestRepository;

    public InterestController(InterestRepository interestRepository){
        this.interestRepository = interestRepository;
    }

    @GetMapping
    public List<InterestEntity> getAllInterests(){
        return interestRepository.findAll();
    }
}