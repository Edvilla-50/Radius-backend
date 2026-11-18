package com.Radius.backend.Entity;   // match your other entities

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "steam_link")
public class SteamLink {

    @Id
    private Long userId;

    @Column(nullable = false, length = 17)
    private String steamId;

    @Column(columnDefinition = "text")
    private String gamesJson;

    private Instant lastFetchedAt;

    protected SteamLink() {}

    public SteamLink(Long userId, String steamId) {
        this.userId = userId;
        this.steamId = steamId;
    }

    public Long getUserId() { return userId; }
    public String getSteamId() { return steamId; }
    public void setSteamId(String steamId) { this.steamId = steamId; }
    public String getGamesJson() { return gamesJson; }
    public void setGamesJson(String gamesJson) { this.gamesJson = gamesJson; }
    public Instant getLastFetchedAt() { return lastFetchedAt; }
    public void setLastFetchedAt(Instant lastFetchedAt) { this.lastFetchedAt = lastFetchedAt; }
}