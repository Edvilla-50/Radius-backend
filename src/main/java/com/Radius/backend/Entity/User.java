package com.Radius.backend.Entity;

import jakarta.persistence.*;//needed for that sweet sweet polymorphism
import java.util.List;//To not duplicate hobbies

import com.Radius.backend.Aspects.Interests;
import com.Radius.backend.Data_Structres.TraitStack;
import com.Radius.backend.Data_Structres.TraitStack.TraitPopResult;

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
    private String emergencyPhoneOne;//forced phone numbers that users must put in case a meetup is unsafe
    private String emergencyPhoneTwo;//another one 
    @Transient
    private TraitStack stack = new TraitStack();
    @Transient
    private double score;


    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(//silly ahh table that I made in data base, SQL am I right?
        name = "user_interests",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "interest_id")
    )
    @OrderColumn(name = "order_index")
    private List<InterestEntity> interests; //FIX to the polymorphism (at least faked)that JPA for some reason did not like
    public User() {}

    public User(String name, int age, List<InterestEntity> interests) {
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

    public List<InterestEntity> getInterests() {
        return interests;
    }

    public void setInterests(List<InterestEntity> interests) {
        this.interests = interests;
    }
    public double getLat(){
        return this.lat;
    }
    public void setLat(double lat){
        this.lat = lat;
    }
    public void setLon(double lon){
        this.lon = lon;
    }
    public void setPerferredDistance(double perferredDistance){
        this.perferredDistance = perferredDistance;
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
    public void pushAllIntrestsToStack(){
        stack = new TraitStack();
        for (int i = this.interests.size() - 1; i >= 0; i--) {
            stack.push(this.interests.get(i).getName());
        }
    }
    public TraitPopResult popOnStack(){
        return stack.pop();
    }
    public int getStackSize(){
        return stack.getLength();
    }
    public void setScore(double score){
        this.score = score;
    }
    public double getScore(){
        return this.score;
    }
    public void resetScore(){
        this.score = 0;
    }
    public String getEmergencyPhoneOne() {
        return emergencyPhoneOne;
    }

    public void setEmergencyPhoneOne(String emergencyPhoneOne) {
        this.emergencyPhoneOne = emergencyPhoneOne;
    }

    public String getEmergencyPhoneTwo() {
        return emergencyPhoneTwo;
    }

    public void setEmergencyPhoneTwo(String emergencyPhoneTwo) {
        this.emergencyPhoneTwo = emergencyPhoneTwo;
    }

}

