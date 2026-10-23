package com.Radius.backend.Entity;

import jakarta.persistence.*;
import org.hibernate.annotations.DynamicUpdate;

import java.time.Duration;
import java.time.Instant;

// @DynamicUpdate: the two phones update different columns on this row
// (acceptedByA vs acceptedByB). Without it, Hibernate writes every column, so a
// request holding a stale copy of the row can overwrite the other user's accept.
@Entity
@DynamicUpdate
public class MeetLocation {

    public static final Duration SESSION_LENGTH = Duration.ofHours(1);

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    // One location row per match. The unique constraint stops two simultaneous
    // "select" calls from creating duplicates (findByMatchId would then throw).
    @Column(unique = true)
    private int matchId;

    private int chooserId;
    private String locationId;
    private String name;
    private String address;
    private Double lat;
    private Double lon;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    // Nullable on purpose: rows created before this column existed have no
    // value, and getExpiresAt() falls back to createdAt + 1 hour for them.
    private Instant expiresAt;

    private boolean acceptedByA;
    private boolean acceptedByB;

    // Set true when an emergency/SOS cancels the meetup. Distinguishes "this
    // meetup was actively cancelled" from "no location has been chosen yet".
    private boolean cancelled = false;

    public MeetLocation() {}

    public MeetLocation(int matchId, int chooserId, String locationId,
            String name, String address, Double lat, Double lon) {
        this.matchId    = matchId;
        this.chooserId  = chooserId;
        this.locationId = locationId;
        this.name       = name;
        this.address    = address;
        this.lat        = lat;
        this.lon        = lon;
        this.createdAt  = Instant.now();
        this.expiresAt  = this.createdAt.plus(SESSION_LENGTH);
    }

    // ---- place / reset ----

    public boolean hasPlace() {
        return locationId != null || name != null;
    }

    // Used by "Pick another" / "Change place": clears the chosen place and both
    // accept flags but keeps the row, so createdAt/expiresAt (the session clock)
    // are NOT restarted and the match stays alive.
    public void clearPlace() {
        this.chooserId = 0;
        this.locationId = null;
        this.name = null;
        this.address = null;
        this.lat = null;
        this.lon = null;
        this.acceptedByA = false;
        this.acceptedByB = false;
    }

    // Sets a (new) place on an existing row without touching the session clock.
    public void setPlace(int chooserId, String locationId, String name,
            String address, Double lat, Double lon) {
        this.chooserId = chooserId;
        this.locationId = locationId;
        this.name = name;
        this.address = address;
        this.lat = lat;
        this.lon = lon;
        this.acceptedByA = false;
        this.acceptedByB = false;
    }

    // ---- expiry ----

    public Instant getExpiresAt() {
        return expiresAt != null ? expiresAt : createdAt.plus(SESSION_LENGTH);
    }

    public boolean isExpired() {
        return Instant.now().isAfter(getExpiresAt());
    }

    // ---- getters / setters ----

    public long getId()           { return id; }
    public int getMatchId()       { return matchId; }
    public int getChooserId()     { return chooserId; }
    public String getLocationId() { return locationId; }
    public String getName()       { return name; }
    public String getAddress()    { return address; }
    public Double getLat()        { return lat; }
    public Double getLon()        { return lon; }
    public Instant getCreatedAt() { return createdAt; }
    public boolean isAcceptedByA()        { return acceptedByA; }
    public void setAcceptedByA(boolean v) { this.acceptedByA = v; }
    public boolean isAcceptedByB()        { return acceptedByB; }
    public void setAcceptedByB(boolean v) { this.acceptedByB = v; }
    public boolean isCancelled()        { return cancelled; }
    public void setCancelled(boolean v) { this.cancelled = v; }
}