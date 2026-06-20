package com.Radius.backend.dto;

import java.util.List;

/**
 * Matches: final results = (_suggestions?["results"] is List) ? ... : [];
 * Serializes to {"results": [...]}
 */
public record SuggestionsResponse(List<SuggestedPlace> results) {}