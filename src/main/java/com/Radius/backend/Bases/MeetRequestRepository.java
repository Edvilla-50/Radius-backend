package com.Radius.backend.Bases;

import org.springframework.data.jpa.repository.JpaRepository;

import com.Radius.backend.Entity.MeetRequest;
import java.util.List;


public interface MeetRequestRepository extends JpaRepository<MeetRequest,Integer>{
    List<MeetRequest> findByReceiverId(int receiverId);
    List<MeetRequest> findByRequesterId(int requesterId);
    
}
