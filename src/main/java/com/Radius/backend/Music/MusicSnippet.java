package com.Radius.backend.Music;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "music_snippet")
public class MusicSnippet {

    @Id
    private Long userId; // one row per Radius user, FK to your user table

    // Store this encrypted at rest (e.g. via a JPA AttributeConverter or
    // column-level encryption) since it authenticates as the user to Apple.
    @Column(name = "apple_music_user_token", length = 2000)
    private String appleMusicUserToken;

    private String trackId;
    private String trackName;
    private String artistName;
    private String albumArtUrl;
    private String previewUrl;
    private Instant lastUpdated;

    // getters and setters omitted for brevity

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getAppleMusicUserToken() { return appleMusicUserToken; }
    public void setAppleMusicUserToken(String t) { this.appleMusicUserToken = t; }

    public String getTrackId() { return trackId; }
    public void setTrackId(String trackId) { this.trackId = trackId; }

    public String getTrackName() { return trackName; }
    public void setTrackName(String trackName) { this.trackName = trackName; }

    public String getArtistName() { return artistName; }
    public void setArtistName(String artistName) { this.artistName = artistName; }

    public String getAlbumArtUrl() { return albumArtUrl; }
    public void setAlbumArtUrl(String albumArtUrl) { this.albumArtUrl = albumArtUrl; }

    public String getPreviewUrl() { return previewUrl; }
    public void setPreviewUrl(String previewUrl) { this.previewUrl = previewUrl; }

    public Instant getLastUpdated() { return lastUpdated; }
    public void setLastUpdated(Instant lastUpdated) { this.lastUpdated = lastUpdated; }
}