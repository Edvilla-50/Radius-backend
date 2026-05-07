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

    private int matchId;     // NEW — identifies the conversation
    private int senderId;    // who sent the message
    private String content;  // message text
    private Long timeStamp;  // unix ms

    public Message() {}

    public Message(int matchId, int senderId, String content) {
        this.matchId = matchId;
        this.senderId = senderId;
        this.content = content;
        this.timeStamp = System.currentTimeMillis();
    }

    public Long getId() {
        return id;
    }

    public int getMatchId() {
        return matchId;
    }

    public void setMatchId(int matchId) {
        this.matchId = matchId;
    }

    public int getSenderId() {
        return senderId;
    }

    public void setSenderId(int senderId) {
        this.senderId = senderId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public Long getTimeStamp() {
        return timeStamp;
    }

    public void setTimeStamp(Long timeStamp) {
        this.timeStamp = timeStamp;
    }
}
