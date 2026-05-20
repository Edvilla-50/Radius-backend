package com.Radius.backend.Entity;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
public class MeetLocation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    private int matchId;
    private int chooserId;
    private String locationId;
    private String name;
    private String address;
    private Double lat;
    private Double lon;

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    private boolean acceptedByA;
    private boolean acceptedByB;

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
    }

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
}