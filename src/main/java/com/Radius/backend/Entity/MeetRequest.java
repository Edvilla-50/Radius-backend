package com.Radius.backend.Entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class MeetRequest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;
    private int requesterId;
    private int receiverId;
    private String status;

    public int getId(){
        return id;
    }
    public int getRequesterId(){
        return requesterId;
    }
    public void setRequesterId(int Rid){
        this.requesterId = Rid;
    }
    public void setRecieverId(int Sid){
        this.receiverId = Sid;
    }
    public int getReceiverId(){
        return receiverId;
    }
    public String getStatus(){
        return status;
    }
    public void setStatus(String Status){
        this.status = Status;
    }
}
