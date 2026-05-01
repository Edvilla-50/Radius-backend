package com.Radius.backend.Entity;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;

@Entity
public class Message {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private int senderId;
    private int receiverId;
    private String content;
    private Long timeStamp;

    public Message(){}

    public Message(int senderId, int receiverId, String content){
        this.senderId = senderId;
        this.receiverId = receiverId;
        this.content = content;
        this.timeStamp = System.currentTimeMillis();
    }
    public void setSenderId(int senderId){
        this.senderId = senderId;
    }
    public int getSenderId(){
        return this.senderId;
    }
    public void setReceiverId(int receiverId){
        this.receiverId = receiverId;
    }
    public int getReceiverId(){
        return this.receiverId;
    }
    public void setContent(String content){
        this.content = content;
    }
    public String getContent(){
        return this.content;
    }
    public Long getId() {
        return id;
    }
    public Long getTimeStamp() {
        return timeStamp;
    }
    public void setTimeStamp(Long timeStamp) {
        this.timeStamp = timeStamp;
    }
}
