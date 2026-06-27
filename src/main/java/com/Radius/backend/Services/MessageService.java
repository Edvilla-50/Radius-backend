package com.Radius.backend.Services;
import com.Radius.backend.Bases.MessageRepository;
import com.Radius.backend.Entity.Message;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Set;

@Service
public class MessageService {

    @Autowired
    private MessageRepository repo;

    private static final Set<String> BLOCKED_WORDS = Set.of(
        "fuck", "shit", "ass", "bitch", "bastard", "damn",
        "crap", "piss", "cock", "dick", "pussy", "cunt",
        "nigger", "nigga", "faggot", "retard", "whore", "slut", "wetback", "kike"
    );

    public String filterContent(String content) {
        if (content == null) return "";
        String[] words = content.split("\\s+");
        StringBuilder filtered = new StringBuilder();
        for (String word : words) {
            String clean = word.replaceAll("[^a-zA-Z]", "").toLowerCase();
            if (BLOCKED_WORDS.contains(clean)) {
                filtered.append("***");
            } else {
                filtered.append(word);
            }
            filtered.append(" ");
        }
        return filtered.toString().trim();
    }

    public Message sendMessage(int matchId, int senderId, String content) {
        String filtered = filterContent(content);
        Message msg = new Message(matchId, senderId, filtered);
        return repo.save(msg);
    }

    public List<Message> getConversation(int matchId) {
        return repo.findByMatchIdOrderByTimeStampAsc(matchId);
    }
}