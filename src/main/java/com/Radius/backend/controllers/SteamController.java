package com.Radius.backend.controllers;

import com.Radius.backend.Entity.SteamLink;                    // keep your real package
import com.Radius.backend.Bases.SteamLinkRepository;      // keep your real package
import com.Radius.backend.Services.RecentGamesResponse;
import com.Radius.backend.Services.SteamService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@RestController
public class SteamController {

    private static final Duration CACHE_TTL = Duration.ofHours(1);
    private static final ObjectMapper MAPPER = new ObjectMapper();

    private final SteamService steamService;
    private final SteamLinkRepository repo;

    @Value("${radius.write.key}")
    private String writeKey;

    public SteamController(SteamService steamService, SteamLinkRepository repo) {
        this.steamService = steamService;
        this.repo = repo;
    }

    // Only requests carrying the shared secret (sent by your PHP) may write
    private boolean authorized(String provided) {
        return provided != null && MessageDigest.isEqual(
                provided.getBytes(StandardCharsets.UTF_8),
                writeKey.getBytes(StandardCharsets.UTF_8));
    }

    // Link (or re-link) a Steam profile from whatever the user pasted
    @PostMapping("/users/{userId}/steam")
    public ResponseEntity<?> link(@PathVariable Long userId,
                                  @RequestBody Map<String, String> body,
                                  @RequestHeader(value = "X-Radius-Key", required = false) String key) {
        if (!authorized(key)) return ResponseEntity.status(401).build();

        try {
            var steamId = steamService.resolveSteamId(body.getOrDefault("input", ""));
            if (steamId.isEmpty()) {
                return ResponseEntity.badRequest().body("Couldn't find that Steam profile.");
            }
            SteamLink link = repo.findById(userId).orElse(new SteamLink(userId, steamId.get()));
            link.setSteamId(steamId.get());
            return ResponseEntity.ok(refresh(link));
        } catch (RestClientException | IllegalStateException e) {
            return ResponseEntity.status(502).body("Steam didn't respond. Try again in a minute.");
        }
    }

    // Read the cached games, refreshing from Steam if the cache is stale (public)
    @GetMapping("/users/{userId}/steam")
    public ResponseEntity<?> get(@PathVariable Long userId) {
        var found = repo.findById(userId);
        if (found.isEmpty()) return ResponseEntity.notFound().build();

        SteamLink link = found.get();
        boolean stale = link.getLastFetchedAt() == null
                || link.getLastFetchedAt().plus(CACHE_TTL).isBefore(Instant.now());
        if (stale) {
            try {
                return ResponseEntity.ok(refresh(link));
            } catch (RestClientException | IllegalStateException e) {
                // Steam is down or slow: fall back to what we already have
            }
        }
        return ResponseEntity.ok(readCached(link));
    }

    // Unlink
    @DeleteMapping("/users/{userId}/steam")
    public ResponseEntity<Void> unlink(@PathVariable Long userId,
                                       @RequestHeader(value = "X-Radius-Key", required = false) String key) {
        if (!authorized(key)) return ResponseEntity.status(401).build();

        if (repo.existsById(userId)) repo.deleteById(userId);
        return ResponseEntity.noContent().build();
    }

    private List<RecentGamesResponse.Game> refresh(SteamLink link) {
        var games = steamService.getRecentGames(link.getSteamId());
        try {
            link.setGamesJson(MAPPER.writeValueAsString(games));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Couldn't serialize games", e);
        }
        link.setLastFetchedAt(Instant.now());
        repo.save(link);
        return games;
    }

    private List<RecentGamesResponse.Game> readCached(SteamLink link) {
        if (link.getGamesJson() == null) return List.of();
        try {
            return MAPPER.readValue(link.getGamesJson(),
                    new TypeReference<List<RecentGamesResponse.Game>>() {});
        } catch (JsonProcessingException e) {
            return List.of();
        }
    }
}