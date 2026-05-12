package com.Radius.backend.Entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.*;
@Entity
public class SafetyRating {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    private String locationId;
    private int userId;

    private boolean wellLit;
    private boolean welcoming;
    private boolean atmosphere;

    private long timeStamp;

    public SafetyRating() {}

    public SafetyRating(String locationId, int userId, boolean wellLit, boolean welcoming, boolean atmosphere){
        this.locationId = locationId;
        this.userId = userId;
        this.wellLit = wellLit;
        this.welcoming = welcoming;
        this.atmosphere = atmosphere;
        this.timeStamp = timeStamp;
    }

    public long getId(){
        return id;
    }
    public String getLocationId(){
        return locationId;
    }
    public int getUserId(){
        return userId;
    }
    public void setLocationId(String locationId){
        this.locationId = locationId;
    }
    public void setUserId(int userId){
        this.userId = userId;
    }
    public boolean isWellLit(){
        return wellLit;
    }
    public void setWellLit(boolean wellLit){
        this.wellLit = wellLit;
    }
    public boolean isWelcoming(){
        return welcoming;
    }
    public void setWelcoming(boolean welcoming){
        this.welcoming = welcoming;
    }
    public boolean isAtmoshphere(){
        return atmosphere;
    }
    public void setAtmopshere(boolean atmosphere){
        this.atmosphere = atmosphere;
    }
    public long getTimeStamp(){
        return timeStamp;
    }
    public void setTimeStamp(Long timestamp){
        this.timeStamp = timeStamp;
    }
}
