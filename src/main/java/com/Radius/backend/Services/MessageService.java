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

    public Message sendMessage(int senderId, int receiverId, String content){
        Message msg = new Message(senderId, receiverId, content);
        return repo.save(msg);
    }
    public List<Message> getConversation(int a, int b) {
        return repo.findConversation(a, b);
    }
}
