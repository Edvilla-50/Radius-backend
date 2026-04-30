package com.Radius.backend.Entity;
import jakarta.persistence.*;

@Entity
@Table(name = "interests")
public class InterestEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private String name;

    private Boolean moneyNeeded;      
    private Boolean disAccessible;
    private String difficulty;
    private String state;
    private String meetUpTime;
    private String category;

    public InterestEntity() {}
    public InterestEntity(String name) { 
        this.name = name; 
    }

    public Long getId() { 
        return id; 
    }
    public String getName() { 
        return name; 
    }
    public void setName(String name) { 
        this.name = name; 
    }
    public Boolean isMoneyNeeded() { 
        return moneyNeeded; 
    }
    public void setMoneyNeeded(Boolean moneyNeeded) { 
        this.moneyNeeded = moneyNeeded; 
    }
    public Boolean isDisAccessible() { 
        return disAccessible; 
    }
    public void setDisAccessible(Boolean disAccessible) { 
        this.disAccessible = disAccessible; 
    }
    public String getDifficulty() { 
        return difficulty; 
    }
    public void setDifficulty(String difficulty) { 
        this.difficulty = difficulty; 
    }
    public String getState() { 
        return state; 
    }
    public void setState(String state) { 
        this.state = state; 
    }
    public String getMeetUpTime() { 
        return meetUpTime; 
    }
    public void setMeetUpTime(String meetUpTime) { 
        this.meetUpTime = meetUpTime; 
    }
    public void setCategory(String category){
        this.category = category;
    }
    public String getCategory(){
        return this.category;
    }
}