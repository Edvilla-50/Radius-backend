package com.Radius.backend.dto;

import java.util.Map;

public record OverpassElement (
    long id,
    String type,
    double lat,
    double lon,
    Coordinate center, // 👈 Added center field to unpack nested polygon coordinates
    Map<String, String> tags
){
    // Companion record to handle nested center attributes from out body center;
    public record Coordinate(double lat, double lon) {}
}