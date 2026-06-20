package com.Radius.backend.dto;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

 @JsonIgnoreProperties(ignoreUnknown = true)
    public record Coordinate(Double lat, Double lon) {}

