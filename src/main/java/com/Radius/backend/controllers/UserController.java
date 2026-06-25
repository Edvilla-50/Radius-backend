package com.Radius.backend.controllers;

import com.Radius.backend.Bases.InterestRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Bases.ReportRepository;
import com.Radius.backend.Bases.UserBlockRepository;
import com.Radius.backend.Entity.LocationUpdate;
import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Entity.UserBlock;

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
    private final MeetRequestRepository meetRequestRepository;
    private final ReportRepository reportRepository;
    private final UserBlockRepository blockRepository;

    public UserController(
        UserRepository repo,
        InterestRepository interestRepository,
        BCryptPasswordEncoder encoder,
        MeetRequestRepository meetRequestRepository,
        ReportRepository reportRepository,
        UserBlockRepository blockRepository
    ) {
        this.repo = repo;
        this.interestRepository = interestRepository;
        this.encoder = encoder;
        this.meetRequestRepository = meetRequestRepository;
        this.reportRepository = reportRepository;
        this.blockRepository = blockRepository;
    }

    @PostMapping("/{id}/location")
    public User updateLocation(@PathVariable long id, @RequestBody LocationUpdate location) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        user.setLat(location.getLat());
        user.setLon(location.getLon());
        return repo.save(user);
    }

    @PostMapping
    public User createUser(@RequestBody User user) {
        return repo.save(user);
    }

    @PutMapping("/{id}/interests")
    public User updateInterests(@PathVariable long id, @RequestBody List<Long> interestIds) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found " + id));
        user.getInterests().clear();
        repo.save(user);

        List<InterestEntity> ordered = interestIds.stream()
            .map(iid -> interestRepository.findById(iid)
                .orElseThrow(() -> new RuntimeException("Interest not found: " + iid)))
            .collect(Collectors.toList());
        user.setInterests(ordered);
        return repo.save(user);
    }

    @GetMapping("/{id}")
    public User getUser(@PathVariable long id) {
        return repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
    }

    @GetMapping("/interests/all")
    public List<InterestEntity> getAllInterests() {
        return interestRepository.findAll();
    }

    @PutMapping("/{id}/profile-html")
    public User updateProfileHtml(@PathVariable long id, @RequestBody Map<String, String> body) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        user.setHtmlProfile(body.get("html"));
        return repo.save(user);
    }

    @GetMapping("/{id}/profile-html")
    public ResponseEntity<?> getProfileHtml(@PathVariable long id) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));

        String html = user.getHtmlProfile();
        if (html == null || html.isBlank()) {
            html = "<html><body style='font-family:Arial;padding:20px;'><h2>No profile yet</h2><p>This user hasn't set up their profile page.</p></body></html>";
        }

        return ResponseEntity.ok(Map.of("html", html));
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
        user.setEmergencyPhone(req.getEmergencyPhone());
        repo.save(user);

        return ResponseEntity.ok(Map.of("userId", user.getId()));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest req) {
        User user = repo.findByEmail(req.getEmail())
            .orElseThrow(() -> new RuntimeException("Invalid email"));
        if (!encoder.matches(req.getPassword(), user.getPassword())) {
            return ResponseEntity.badRequest().body("Invalid credentials");
        }

        return ResponseEntity.ok(Map.of(
            "userId", user.getId(),
            "name", user.getName()
        ));
    }

    @PostMapping("/{id}/preferred-distance")
    public ResponseEntity<?> updatePreferredDistance(@PathVariable long id, @RequestBody Map<String, Double> body) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        user.setPerferredDistance(body.get("distance"));
        repo.save(user);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{id}/ghost-mode")
    public ResponseEntity<?> updateGhostMode(@PathVariable long id, @RequestBody Map<String, Boolean> body) {
        User user = repo.findById(id)
            .orElseThrow(() -> new RuntimeException("User not found: " + id));
        user.setGhostMode(body.get("ghostMode"));
        repo.save(user);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/fcm-token")
    public ResponseEntity<?> updateFcmToken(@RequestBody Map<String, Object> body) {
        Long userId = Long.valueOf(body.get("userId").toString());
        String fcmToken = body.get("fcmToken").toString();

        User user = repo.findById(userId)
            .orElseThrow(() -> new RuntimeException("User not found: " + userId));
        user.setFcmToken(fcmToken);
        repo.save(user);

        return ResponseEntity.ok().build();
    }

    // ----------------------------------------------------------------
    // BLOCK USER
    // ----------------------------------------------------------------
    @PostMapping("/{id}/block/{blockedId}")
    public ResponseEntity<?> blockUser(@PathVariable long id, @PathVariable long blockedId) {
        if (id == blockedId) {
            return ResponseEntity.badRequest().body("Cannot block yourself");
        }
        if (!blockRepository.existsByBlockerIdAndBlockedId(id, blockedId)) {
            blockRepository.save(new UserBlock(id, blockedId));
        }
        return ResponseEntity.ok(Map.of("message", "User blocked"));
    }

    // ----------------------------------------------------------------
    // ACCOUNT DELETION
    // ----------------------------------------------------------------
    @DeleteMapping("/{id}")
    @org.springframework.transaction.annotation.Transactional
    public ResponseEntity<?> deleteAccount(@PathVariable long id) {
        try {
            User user = repo.findById(id)
                .orElseThrow(() -> new RuntimeException("User not found: " + id));

            user.getInterests().clear();
            repo.save(user);

            List<MeetRequest> sent = meetRequestRepository.findByRequesterId((int) id);
            List<MeetRequest> received = meetRequestRepository.findByReceiverId((int) id);
            meetRequestRepository.deleteAll(sent);
            meetRequestRepository.deleteAll(received);

            reportRepository.deleteAll(reportRepository.findByReporterId((int) id));
            reportRepository.deleteAll(reportRepository.findByReportedUserId((int) id));

            // Delete blocks involving this user
            blockRepository.deleteAll(blockRepository.findByBlockerId(id));
            blockRepository.deleteAll(blockRepository.findByBlockedId(id));

            repo.delete(user);

            return ResponseEntity.ok(Map.of("message", "Account deleted successfully"));

        } catch (Exception e) {
            return ResponseEntity.internalServerError()
                .body(Map.of("error", "Failed to delete account: " + e.getMessage()));
        }
    }
}