package com.Radius.backend.Entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;

import java.time.Instant;


@Entity
@Table(
        name = "cached_place_searches",
        uniqueConstraints = @UniqueConstraint(columnNames = {"tileKey", "querySignature"})
)
public class CachedPlaceSearch {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String tileKey;

    @Column(nullable = false)
    private String querySignature;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String resultsJson;

    @Column(nullable = false)
    private Instant cachedAt;

    protected CachedPlaceSearch() {
        // required by JPA
    }

    public CachedPlaceSearch(String tileKey, String querySignature, String resultsJson, Instant cachedAt) {
        this.tileKey = tileKey;
        this.querySignature = querySignature;
        this.resultsJson = resultsJson;
        this.cachedAt = cachedAt;
    }

    public Long getId() {
        return id;
    }

    public String getTileKey() {
        return tileKey;
    }

    public String getQuerySignature() {
        return querySignature;
    }

    public String getResultsJson() {
        return resultsJson;
    }

    public Instant getCachedAt() {
        return cachedAt;
    }

    public void setResultsJson(String resultsJson) {
        this.resultsJson = resultsJson;
    }

    public void setCachedAt(Instant cachedAt) {
        this.cachedAt = cachedAt;
    }
}