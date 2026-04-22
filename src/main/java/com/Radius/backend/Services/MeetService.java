package com.Radius.backend.Services;

import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Bases.MeetRequestRepository;
import org.springframework.stereotype.Service;

@Service
public class MeetService {

    private final MeetRequestRepository repo;

    public MeetService(MeetRequestRepository repo) {
        this.repo = repo;
    }

    public void sendMeetRequest(int requesterId, int receiverId) {
        MeetRequest req = new MeetRequest();
        req.setRequesterId(requesterId);
        req.setRecieverId(receiverId);
        req.setStatus("pending");

        repo.save(req);
    }
}

