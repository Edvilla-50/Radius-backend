package com.Radius.backend.Services;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import java.util.List;

@JsonIgnoreProperties(ignoreUnknown = true)
public record RecentGamesResponse(Inner response) {

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Inner(Integer total_count, List<Game> games) {}

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Game(long appid, String name,
                       int playtime_2weeks, int playtime_forever) {}
}