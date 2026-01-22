package com.Radius.backend.Entity;
import com.Radius.backend.Aspects.*;
import jakarta.persistence.*;

@Entity
@Table(name = "interests")//Transition to acceptable JPA polymorhpism, well its called persistence I guess
public class InterestEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private String name;

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
}

