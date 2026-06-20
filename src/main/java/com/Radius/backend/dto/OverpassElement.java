package com.Radius.backend.dto;

import java.util.Map;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record OverpassElement (
    long id,
    String type,
    Double lat,          // Changed from double -> Double to allow safe null handling
    Double lon,          // Changed from double -> Double to allow safe null handling
    Coordinate center,   // Unpacks nested polygon center coordinate objects
    Map<String, String> tags
){
    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Coordinate(double lat, double lon) {}
}