package com.Radius.backend.Bases;

import com.Radius.backend.Entity.MeetLocation;

import jakarta.transaction.Transactional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface MeetLocationRepository extends JpaRepository<MeetLocation, Long> {

    MeetLocation findByMatchId(int matchId);
    @Modifying
    @Transactional
    @Query(value = "DELETE FROM meet_location WHERE created_at < NOW() - INTERVAL '1 hour'", nativeQuery = true)
    void deleteExpired();
}
