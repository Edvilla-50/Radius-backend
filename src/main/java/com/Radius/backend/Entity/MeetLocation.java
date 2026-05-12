package com.Radius.backend.Entity;
import jakarta.persistence.*;
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
    private Long timeStamp;

    public MeetLocation(){}

    public MeetLocation(int matchId, int chooserId, String locationId, String name, String address) {
        this.matchId = matchId;
        this.chooserId = chooserId;
        this.locationId = locationId;
        this.name = name;
        this.address = address;
        this.timeStamp = System.currentTimeMillis();
    }
    public Long getId() { 
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
    public Long getTimeStamp() { 
        return timeStamp; 
    }
}
