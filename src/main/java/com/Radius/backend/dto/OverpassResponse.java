package com.Radius.backend.dto;

import java.util.List;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true) // 👈 Prevents crashing on extra OSM meta fields
public record OverpassResponse(
    List<OverpassElement> elements
) {}

