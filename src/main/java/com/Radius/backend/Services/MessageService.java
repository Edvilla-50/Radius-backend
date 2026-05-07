package com.Radius.backend.Services;

import com.Radius.backend.Bases.MessageRepository;
import com.Radius.backend.Entity.Message;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class MessageService {

    @Autowired
    private MessageRepository repo;

    // Save a message for a matchId conversation
    public Message sendMessage(int matchId, int senderId, String content) {
        Message msg = new Message(matchId, senderId, content);
        return repo.save(msg);
    }

    // Load all messages for a matchId
    public List<Message> getConversation(int matchId) {
        return repo.findByMatchIdOrderByTimeStampAsc(matchId);
    }
}
