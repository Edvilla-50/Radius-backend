package com.Radius.backend.Music;

import com.fasterxml.jackson.databind.JsonNode;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

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

    public RecentTrack getMostRecentTrack(String userToken) throws Exception {

        if (userToken == null || userToken.isBlank()) {
            throw new IllegalArgumentException(
                    "Apple Music user token is missing."
            );
        }

        String devToken = tokenService.getDeveloperToken();

        HttpHeaders headers = new HttpHeaders();
        headers.set("Authorization", "Bearer " + devToken);
        headers.set("Music-User-Token", userToken);
        headers.set("Accept", "application/json");

        try {

            ResponseEntity<JsonNode> response = restTemplate.exchange(
                    RECENT_TRACKS_URL,
                    HttpMethod.GET,
                    new HttpEntity<>(headers),
                    JsonNode.class
            );

            JsonNode body = response.getBody();

            System.out.println("Apple Music recent tracks status: "
                    + response.getStatusCode());

            System.out.println("Apple Music recent tracks response: "
                    + body);

            if (body == null) {
                return null;
            }

            JsonNode data = body.path("data");

            if (!data.isArray() || data.isEmpty()) {
                return null;
            }

            JsonNode track = data.get(0);

            String trackId = track.path("id").asText(null);

            if (trackId == null || trackId.isBlank()) {
                return null;
            }

            JsonNode attrs = track.path("attributes");

            RecentTrack result = new RecentTrack();

            result.trackId = trackId;
            result.trackName = attrs.path("name").asText("");
            result.artistName = attrs.path("artistName").asText("");

            String artworkUrl =
                    attrs.path("artwork").path("url").asText("");

            if (!artworkUrl.isBlank()) {
                result.albumArtUrl = artworkUrl
                        .replace("{w}", "300")
                        .replace("{h}", "300");
            }

            JsonNode previews = attrs.path("previews");

            if (previews.isArray() && !previews.isEmpty()) {

                result.previewUrl =
                        previews.get(0).path("url").asText(null);

            } else {

                result.previewUrl =
                        lookupPreviewUrl(trackId, devToken);
            }

            return result;

        } catch (HttpStatusCodeException e) {

            System.err.println(
                    "=========================================="
            );

            System.err.println(
                    "APPLE MUSIC RECENT TRACKS ERROR"
            );

            System.err.println(
                    "HTTP STATUS: " + e.getStatusCode()
            );

            System.err.println(
                    "RESPONSE BODY: " + e.getResponseBodyAsString()
            );

            System.err.println(
                    "=========================================="
            );

            throw new RuntimeException(
                    "Apple Music recent tracks request failed: "
                            + e.getStatusCode()
                            + " "
                            + e.getResponseBodyAsString(),
                    e
            );
        }
    }

    private String lookupPreviewUrl(
            String trackId,
            String devToken
    ) {

        HttpHeaders headers = new HttpHeaders();

        headers.set("Authorization", "Bearer " + devToken);
        headers.set("Accept", "application/json");

        String url = String.format(
                CATALOG_SONG_URL_TEMPLATE,
                trackId
        );

        try {

            ResponseEntity<JsonNode> response =
                    restTemplate.exchange(
                            url,
                            HttpMethod.GET,
                            new HttpEntity<>(headers),
                            JsonNode.class
                    );

            JsonNode body = response.getBody();

            if (body == null) {
                return null;
            }

            JsonNode data = body.path("data");

            if (!data.isArray() || data.isEmpty()) {
                return null;
            }

            JsonNode song = data.get(0);

            JsonNode previews =
                    song.path("attributes").path("previews");

            if (previews.isArray() && !previews.isEmpty()) {

                return previews
                        .get(0)
                        .path("url")
                        .asText(null);
            }

        } catch (HttpStatusCodeException e) {

            System.err.println(
                    "Apple Music catalog lookup failed: "
                            + e.getStatusCode()
                            + " "
                            + e.getResponseBodyAsString()
            );
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
