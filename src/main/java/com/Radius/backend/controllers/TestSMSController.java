package com.Radius.backend.Controllers;

import com.Radius.backend.Models.User;
import com.Radius.backend.Services.EmergencyAlertService;
import com.Radius.backend.Repositories.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/emergency")
public class EmergencyController {

    private final EmergencyAlertService emergencyAlertService;
    private final UserRepository userRepository;

    public EmergencyController(EmergencyAlertService emergencyAlertService, UserRepository userRepository) {
        this.emergencyAlertService = emergencyAlertService;
        this.userRepository = userRepository;
    }

    @PostMapping("/alert")
    public ResponseEntity<String> sendAlert(
            @RequestParam Long userId,
            @RequestParam double lat,
            @RequestParam double lon,
            @RequestParam(required = false, defaultValue = "") String note) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        emergencyAlertService.sendEmergencyAlert(user, lat, lon, note);

        return ResponseEntity.ok("Emergency alert sent");
    }
}