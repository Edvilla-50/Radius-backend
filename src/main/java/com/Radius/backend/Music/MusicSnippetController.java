package com.Radius.backend.Music;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.Duration;
import java.time.Instant;

interface MusicSnippetRepository extends JpaRepository<MusicSnippet, Long> {}

@RestController
@RequestMapping("/api/music")
public class MusicSnippetController {

    private static final Duration REFRESH_INTERVAL = Duration.ofMinutes(20);

    private final MusicSnippetRepository repository;
    private final AppleMusicService appleMusicService;

    public MusicSnippetController(
            MusicSnippetRepository repository,
            AppleMusicService appleMusicService
    ) {
        this.repository = repository;
        this.appleMusicService = appleMusicService;
    }

    @PostMapping("/connect/{userId}")
    public MusicSnippet connect(
            @PathVariable Long userId,
            @RequestBody ConnectRequest req
    ) throws Exception {

        if (req == null
                || req.appleMusicUserToken == null
                || req.appleMusicUserToken.isBlank()) {
            throw new IllegalArgumentException(
                    "Apple Music user token is missing."
            );
        }

        MusicSnippet snippet =
                repository.findById(userId).orElse(new MusicSnippet());

        snippet.setUserId(userId);
        snippet.setAppleMusicUserToken(req.appleMusicUserToken);

        refreshFromApple(snippet);

        return repository.save(snippet);
    }

    @GetMapping("/{userId}")
    public MusicSnippet getSnippet(
            @PathVariable Long userId
    ) throws Exception {

        MusicSnippet snippet =
                repository.findById(userId).orElse(null);

        if (snippet == null
                || snippet.getAppleMusicUserToken() == null
                || snippet.getAppleMusicUserToken().isBlank()) {
            return null;
        }

        boolean stale =
                snippet.getLastUpdated() == null
                        || Instant.now().isAfter(
                                snippet.getLastUpdated().plus(REFRESH_INTERVAL)
                        );

        if (stale) {
            refreshFromApple(snippet);
            repository.save(snippet);
        }

        return snippet;
    }

    @DeleteMapping("/disconnect/{userId}")
    public ResponseEntity<Void> disconnect(
            @PathVariable Long userId
    ) {

        if (repository.existsById(userId)) {
            repository.deleteById(userId);
        }

        return ResponseEntity.noContent().build();
    }

    public void refreshFromApple(MusicSnippet snippet) throws Exception {

        if (snippet == null
                || snippet.getAppleMusicUserToken() == null
                || snippet.getAppleMusicUserToken().isBlank()) {
            return;
        }

        AppleMusicService.RecentTrack track =
                appleMusicService.getMostRecentTrack(
                        snippet.getAppleMusicUserToken()
                );

        if (track != null) {
            snippet.setTrackId(track.trackId);
            snippet.setTrackName(track.trackName);
            snippet.setArtistName(track.artistName);
            snippet.setAlbumArtUrl(track.albumArtUrl);
            snippet.setPreviewUrl(track.previewUrl);
        }

        snippet.setLastUpdated(Instant.now());
    }

    public static class ConnectRequest {
        public String appleMusicUserToken;
    }
}
