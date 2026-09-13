package com.Radius.backend.Music;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

/**
 * Talks to Apple's Music API for:
 *  - the user's most recently played track (needs their Music User Token)
 *  - that track's 30-second preview URL (catalog lookup, developer token only)
 */
@Service
public class AppleMusicService {

    private static final String RECENT_TRACKS_URL =
            "https://api.music.apple.com/v1/me/recent/played/tracks?limit=1";

    private static final String CATALOG_SONG_URL_TEMPLATE =
            "https://api.music.apple.com/v1/catalog/us/songs/%s";

    @Autowired
    private MusicKitTokenService tokenService;

    @Autowired
    private RestTemplate restTemplate;

    /**
     * Fetches the single most recently played track for a user.
     * Requires their stored Apple Music user token (from the MusicKit
     * authorization flow on the client).
     */
    public RecentTrack getMostRecentTrack(String userToken) throws Exception {
        String devToken = tokenService.getDeveloperToken();

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + devToken);
        headers.set("Music-User-Token", userToken);

        ResponseEntity<JsonNode> response = restTemplate.exchange(
                RECENT_TRACKS_URL, HttpMethod.GET, new HttpEntity<>(headers), JsonNode.class);

        JsonNode data = response.getBody().path("data");
        if (!data.isArray() || data.isEmpty()) {
            return null; // user has no recent plays, or history unavailable
        }

        JsonNode track = data.get(0);
        String trackId = track.path("id").asText();
        JsonNode attrs = track.path("attributes");

        RecentTrack result = new RecentTrack();
        result.trackId = trackId;
        result.trackName = attrs.path("name").asText();
        result.artistName = attrs.path("artistName").asText();
        result.albumArtUrl = attrs.path("artwork").path("url").asText()
                .replace("{w}", "300").replace("{h}", "300");

        // Preview URL often comes back in the same attributes payload —
        // fall back to a catalog lookup if it's missing.
        JsonNode previews = attrs.path("previews");
        if (previews.isArray() && previews.size() > 0) {
            result.previewUrl = previews.get(0).path("url").asText();
        } else {
            result.previewUrl = lookupPreviewUrl(trackId, devToken);
        }

        return result;
    }

    private String lookupPreviewUrl(String trackId, String devToken) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + devToken);

        String url = String.format(CATALOG_SONG_URL_TEMPLATE, trackId);
        ResponseEntity<JsonNode> response = restTemplate.exchange(
                url, HttpMethod.GET, new HttpEntity<>(headers), JsonNode.class);

        JsonNode song = response.getBody().path("data").get(0);
        JsonNode previews = song.path("attributes").path("previews");
        if (previews.isArray() && previews.size() > 0) {
            return previews.get(0).path("url").asText();
        }
        return null;
    }

    public static class RecentTrack {
        public String trackId;
        public String trackName;
        public String artistName;
        public String albumArtUrl;
        public String previewUrl;
    }
}