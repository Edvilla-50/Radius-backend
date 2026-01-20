package com.Radius.backend.Entity;
import jakarta.persistence.*;
import java.util.Set;
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private int age;
    @ElementCollection//makes a table called user_interests, it isnt another silly ahh entity, just a table that maps a user to their interests via a id
    @CollectionTable(name="user_interests", joinColumns = @JoinColumn(name = "user_id"))
    private Set<String> interests;
    //constuctors, really, yeah who knew to have a object it needs to be made first, common sense man
    public User(){}
    public User(String name, int age, Set<String> interests){
        this.name = name;
        this.age = age;
        this.interests = interests;
    }
    public Long getId(){
        return id;
    }
    public String getName(){
        return name;
    }
    public void setInterests(Set<String> interests){//remember everyone is diffrent, so you gotta use this.interests, I love you man
        this.interests = interests;
    }
    public Set<String> getInterests(){
        return interests;
    }
    public void setId(Long id){//dont code to country music man, I really didnt want to push this because luke combs came on
        this.id = id;
    }
    public void setName(String name){
        this.name = name;
    }
    public int getAge(){//someone cant change ages dummy
        return age;
    }


}   