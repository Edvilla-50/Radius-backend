package com.Radius.backend.dto;

import java.util.Map;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

 @JsonIgnoreProperties(ignoreUnknown = true)
    public record Coordinate(double lat, double lon) {}

