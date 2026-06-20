package com.Radius.backend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;


public record PlaceLocation(
        @JsonProperty("formatted_address") String formattedAddress
) {}