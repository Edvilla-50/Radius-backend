package com.Radius.backend.Entity;

import jakarta.persistence.*;//needed for that sweet sweet polymorphism
import java.util.Set;//To not duplicate hobbies

import com.Radius.backend.Aspects.Interests;
import com.Radius.backend.Data_Structres.TraitStack;

@Entity
@Table(name = "users")
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;
    private int age;
    private double lon;
    private double lat;
    private double perferredDistance;
    private int minAgePref;
    private int maxAgePref;
    private String emergencyPhoneOne;//forced phone numbers that users must put in case a meetup hits the shitfan, I guess
    private String emergencyPhoneTwo;//another one -DJ Khaled
    @Transient
    private TraitStack stack;
    private float score;


    @ManyToMany
    @JoinTable(//silly ahh table that I made in data base, SQL am I right?
        name = "user_interests",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "interest_id")
    )
    private Set<InterestEntity> interests; //FIX to the polymorphism (at least faked)that JPA for some reason did not fw
    public User() {}

    public User(String name, int age, Set<InterestEntity> interests) {
        this.name = name;
        this.age = age;
        this.interests = interests;
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

    public int getAge() { 
        return age; 
    }

    public Set<InterestEntity> getInterests() {
        return interests;
    }

    public void setInterests(Set<InterestEntity> interests) {
        this.interests = interests;
    }
    public double getLat(){
        return this.lat;
    }
    public double getLon(){
        return this.lon;
    }
    public double getPerferredDistance(){
        return this.perferredDistance;
    }
    public int getMinAgePref(){
        return this.minAgePref;
    }
    public int maxMinAgePref(){
        return this.maxAgePref;
    }
    public String getEmergencyOne(){
        return this.emergencyPhoneOne;
    }
    public void pushAllIntrestsToStack(){
       for (InterestEntity interest : this.interests) {
            stack.push(interest.getName());
        }
    }
    public String popOnStack(){
        return stack.pop();
    }
    public int getStackSize(){
        return stack.getLength();
    }
    public void setScore(float score){
        this.score = score;
    }
    public float getScore(){
        return this.score;
    }
}
