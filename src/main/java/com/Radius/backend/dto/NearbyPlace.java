package com.Radius.backend.dto;

public record NearbyPlace (
    long id,
    String name,
    String category,
    double lat,
    double lon,
    String openingHours
 ) {}
