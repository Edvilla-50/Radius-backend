package com.Radius.backend.dto;
import com.Radius.backend.dto.PlaceLocation;
import com.fasterxml.jackson.annotation.JsonProperty;

public record SuggestedPlace(
        @JsonProperty("fsq_place_id") String fsqPlaceId,
        String name,
        PlaceLocation location,
        double latitude,
        double longitude
) {}
 

