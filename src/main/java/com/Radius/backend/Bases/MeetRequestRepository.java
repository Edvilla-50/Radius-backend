package com.Radius.backend.Bases;

import org.springframework.data.jpa.repository.JpaRepository;

import com.Radius.backend.Entity.MeetRequest;
import java.util.List;


public interface MeetRequestRepository extends JpaRepository<MeetRequest, Integer> {

    // All pending requests for a receiver
    List<MeetRequest> findByReceiverIdAndStatus(int receiverId, String status);

    // All pending requests sent by a user
    List<MeetRequest> findByRequesterIdAndStatus(int requesterId, String status);

    // ONE pending request for popup
    MeetRequest findFirstByReceiverIdAndStatus(int receiverId, String status);
}

