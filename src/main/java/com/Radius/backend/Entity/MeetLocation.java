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

    @Column(nullable = false, updatable = false)
    private Instant createdAt = Instant.now();

    private boolean acceptedByA;
    private boolean acceptedByB;

    public MeetLocation() {}

    public MeetLocation(int matchId, int chooserId, String locationId, String name, String address) {
        this.matchId = matchId;
        this.chooserId = chooserId;
        this.locationId = locationId;
        this.name = name;
        this.address = address;
        this.createdAt = Instant.now();
    }

    public long getId() {
        return id;
    }

    public int getMatchId() {
        return matchId;
    }

    public int getChooserId() {
        return chooserId;
    }

    public String getLocationId() {
        return locationId;
    }

    public String getName() {
        return name;
    }

    public String getAddress() {
        return address;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public boolean isAcceptedByA() {
        return acceptedByA;
    }

    public void setAcceptedByA(boolean acceptedByA) {
        this.acceptedByA = acceptedByA;
    }

    public boolean isAcceptedByB() {
        return acceptedByB;
    }

    public void setAcceptedByB(boolean acceptedByB) {
        this.acceptedByB = acceptedByB;
    }
}
