package com.Radius.backend.dto;


import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

 @JsonIgnoreProperties(ignoreUnknown = true)
    public record Coordinate(double lat, double lon) {}

