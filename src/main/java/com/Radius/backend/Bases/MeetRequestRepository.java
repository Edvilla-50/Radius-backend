package com.Radius.backend.Bases;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.web.bind.annotation.ModelAttribute;

import com.Radius.backend.Entity.MeetRequest;

import jakarta.transaction.Transactional;

import java.util.List;
import java.util.Optional;

public interface MeetRequestRepository extends JpaRepository<MeetRequest, Integer> {

    List<MeetRequest> findByReceiverIdAndStatus(int receiverId, String status);

    List<MeetRequest> findByRequesterIdAndStatus(int requesterId, String status);

    MeetRequest findFirstByReceiverIdAndStatus(int receiverId, String status);

    Optional<MeetRequest> findByRequesterIdAndReceiverId(int requesterId, int receiverId);

    List<MeetRequest> findByReceiverId(int receiverId);

    List<MeetRequest> findByRequesterId(int requesterId);

    @Modifying
    @Transactional
    @Query(value = "DELETE FROM meet_request WHERE created_at < NOW() - INTERVAL '1 hour'", nativeQuery = true)
    void deleteExpired();
}

