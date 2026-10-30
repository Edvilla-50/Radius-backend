package com.Radius.backend.Services;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class SteamService {

    private static final Pattern STEAM_ID = Pattern.compile("\\d{17}");

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    private final RestClient client = RestClient.create("https://api.steampowered.com");
    private final String apiKey;

    public SteamService(@Value("${steam.api.key}") String apiKey) {
        this.apiKey = apiKey;
    }

    public Optional<String> resolveSteamId(String input) {
        String s = input.trim().replaceAll("/+$", "");

        // 17-digit ID anywhere in the input (bare ID or /profiles/ link)
        if (s.contains("/profiles/") || STEAM_ID.matcher(s).matches()) {
            Matcher m = STEAM_ID.matcher(s);
            return m.find() ? Optional.of(m.group()) : Optional.empty();
        }

        // Otherwise treat it as a custom name: from /id/name or just "name"
        String vanity = s.contains("/id/") ? s.substring(s.lastIndexOf("/id/") + 4) : s;
        if (!vanity.matches("[A-Za-z0-9_-]{2,64}")) return Optional.empty();

        String raw = client.get()
                .uri(u -> u.path("/ISteamUser/ResolveVanityURL/v1/")
                        .queryParam("key", apiKey)
                        .queryParam("vanityurl", vanity).build())
                .retrieve().body(String.class);

        if (raw == null) return Optional.empty();
        try {
            JsonNode res = MAPPER.readTree(raw);
            if (res.path("response").path("success").asInt() != 1) return Optional.empty();
            return Optional.of(res.path("response").path("steamid").asText());
        } catch (JsonProcessingException e) {
            return Optional.empty();
        }
    }

    public List<RecentGamesResponse.Game> getRecentGames(String steamId) {
        String raw = client.get()
                .uri(u -> u.path("/IPlayerService/GetRecentlyPlayedGames/v1/")
                        .queryParam("key", apiKey)
                        .queryParam("steamid", steamId)
                        .queryParam("count", 3).build())
                .retrieve().body(String.class);

        if (raw == null) return List.of();
        try {
            var res = MAPPER.readValue(raw, RecentGamesResponse.class);
            if (res.response() == null || res.response().games() == null) return List.of();
            return res.response().games();   // empty for private profiles
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("Couldn't read Steam response", e);
        }
    }
}