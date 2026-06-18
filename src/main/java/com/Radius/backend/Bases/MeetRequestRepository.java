package com.Radius.backend.Bases;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    // FIXES MEETSERVICE COMPILATION ERROR: Tells Spring Data to fetch rows by matchId
    List<MeetRequest> findByMatchId(int matchId);

    // CRITICAL TERMINATION QUERY: Updates both records to CANCELLED instantly
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Transactional
    @Query("UPDATE MeetRequest m SET m.status = 'CANCELLED' WHERE m.matchId = :matchId")
    void terminateMatchSession(@Param("matchId") int matchId);

    @Modifying
    @Transactional
    @Query(value = "DELETE FROM meet_request WHERE created_at < NOW() - INTERVAL '1 hour'", nativeQuery = true)
    void deleteExpired();
}