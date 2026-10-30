package com.Radius.backend.Services;

import com.fasterxml.jackson.databind.JsonNode;
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

        var res = client.get()
            .uri(u -> u.path("/ISteamUser/ResolveVanityURL/v1/")
                .queryParam("key", apiKey)
                .queryParam("vanityurl", vanity).build())
            .retrieve().body(JsonNode.class);

        if (res == null || res.path("response").path("success").asInt() != 1)
            return Optional.empty();
        return Optional.of(res.path("response").path("steamid").asText());
    }

    public List<RecentGamesResponse.Game> getRecentGames(String steamId) {
        var res = client.get()
            .uri(u -> u.path("/IPlayerService/GetRecentlyPlayedGames/v1/")
                .queryParam("key", apiKey)
                .queryParam("steamid", steamId)
                .queryParam("count", 3).build())
            .retrieve().body(RecentGamesResponse.class);

        if (res == null || res.response() == null || res.response().games() == null)
            return List.of();   // private profile or no recent games
        return res.response().games();
    }
}