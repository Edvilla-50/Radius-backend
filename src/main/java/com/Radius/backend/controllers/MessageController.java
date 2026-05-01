package com.Radius.backend.controllers;

import com.Radius.backend.Entity.Message;
import com.Radius.backend.Services.MessageService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;


@RestController
@RequestMapping("/messages")
@CrossOrigin(origins =  "*")
public class MessageController {
    @Autowired
    private MessageService service;

    @PostMapping("/send")
    public Message sendMessage(@RequestBody Map<String, Object> body){
        int senderId = (int) body.get("senderId");
        int receiverId = (int) body.get("receiverId");
        String content = (String) body.get("content");

        return service.sendMessage(senderId, receiverId, content);
    }
    @GetMapping("/conversation/{a}/{b}")
    public List<Message> getConversation(@PathVariable int a, @PathVariable int b){
        return service.getConversation(a, b);
    }
}
