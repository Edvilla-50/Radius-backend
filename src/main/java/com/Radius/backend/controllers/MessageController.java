package com.Radius.backend.controllers;

import com.Radius.backend.Entity.Message;
import com.Radius.backend.Services.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/messages")
public class MessageController {

    @Autowired
    private MessageService service;

    @PostMapping("/send")
    public Message sendMessage(@RequestBody Map<String, Object> body) {
        int matchId = ((Number) body.get("matchId")).intValue();
        int senderId = ((Number) body.get("senderId")).intValue();
        String content = (String) body.get("content");

        return service.sendMessage(matchId, senderId, content);
    }

    @GetMapping("/conversation/{matchId}")
    public List<Message> getConversation(@PathVariable int matchId) {
        return service.getConversation(matchId);
    }
}