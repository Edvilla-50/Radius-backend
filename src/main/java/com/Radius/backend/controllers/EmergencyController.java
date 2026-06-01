package com.Radius.backend.controllers;

import com.Radius.backend.Entity.User;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Services.TextBeltService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/emergency")
public class EmergencyController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private TextBeltService textBeltService;

    @PostMapping("/alert")
    public ResponseEntity<?> sendAlert(@RequestBody Map<String, Object> body) {
        int userId = (int) body.get("userId");
        double lat = ((Number) body.get("lat")).doubleValue();
        double lon = ((Number) body.get("lon")).doubleValue();
        String type = (String) body.get("type");
        String note = (String) body.getOrDefault("note", "");

        Optional<User> userOpt = userRepository.findById((long) userId);
        if (userOpt.isEmpty()) {
            return ResponseEntity.badRequest().body("User not found");
        }

        User user = userOpt.get();
        String emergencyPhone = user.getEmergencyPhone();

        if (emergencyPhone == null || emergencyPhone.isBlank()) {
            return ResponseEntity.badRequest().body("No emergency contact on file");
        }

        textBeltService.sendEmergencyAlert(emergencyPhone, type, lat, lon, note);

        return ResponseEntity.ok().build();
    }
}