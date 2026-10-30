package com.Radius.backend.controllers;   // match your other controllers

import com.Radius.backend.Entity.SteamLink;
import com.Radius.backend.Bases.SteamLinkRepository;
import com.Radius.backend.Services.RecentGamesResponse;
import com.Radius.backend.Services.SteamService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.client.RestClientException;

import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;

@RestController
public class SteamController {

    private static final Duration CACHE_TTL = Duration.ofHours(1);

    private final SteamService steamService;
    private final SteamLinkRepository repo;
    private final ObjectMapper mapper;

    public SteamController(SteamService steamService, SteamLinkRepository repo, ObjectMapper mapper) {
        this.steamService = steamService;
        this.repo = repo;
        this.mapper = mapper;
    }

    // Link (or re-link) a Steam profile from whatever the user pasted
    @PostMapping("/users/{userId}/steam")
    public ResponseEntity<?> link(@PathVariable Long userId, @RequestBody Map<String, String> body) {
        var steamId = steamService.resolveSteamId(body.getOrDefault("input", ""));
        if (steamId.isEmpty()) {
            return ResponseEntity.badRequest().body("Couldn't find that Steam profile.");
        }
        SteamLink link = repo.findById(userId).orElse(new SteamLink(userId, steamId.get()));
        link.setSteamId(steamId.get());
        return ResponseEntity.ok(refresh(link));
    }

    // Read the cached games, refreshing from Steam if the cache is stale
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
            } catch (RestClientException e) {
                // Steam is down or slow: fall back to what we already have
            }
        }
        return ResponseEntity.ok(readCached(link));
    }

    // Unlink
    @DeleteMapping("/users/{userId}/steam")
    public ResponseEntity<Void> unlink(@PathVariable Long userId) {
        if (repo.existsById(userId)) repo.deleteById(userId);
        return ResponseEntity.noContent().build();
    }

    private List<RecentGamesResponse.Game> refresh(SteamLink link) {
        var games = steamService.getRecentGames(link.getSteamId());
        try {
            link.setGamesJson(mapper.writeValueAsString(games));
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
            return mapper.readValue(link.getGamesJson(),
                    new TypeReference<List<RecentGamesResponse.Game>>() {});
        } catch (JsonProcessingException e) {
            return List.of();
        }
    }
}