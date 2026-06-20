package com.Radius.backend.dto;

import java.util.Map;

public record OverpassElement (
    long id,
    String type,
    double lat,
    double lon,
    Map<String, String> tags
){}
