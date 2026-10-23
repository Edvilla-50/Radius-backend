package com.Radius.backend.Bases;

import com.Radius.backend.Entity.MeetLocation;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

public interface MeetLocationRepository extends JpaRepository<MeetLocation, Long> {

    MeetLocation findByMatchId(int matchId);

    // UNCHANGED for now: deletes rows an hour after creation. Whatever calls this
    // today may rely on it. Once MeetLocationService reports expiry from
    // expiresAt, switch callers to purgeLongExpired() below.
    @Modifying
    @Transactional
    @Query(value = "DELETE FROM meet_location WHERE created_at < NOW() - INTERVAL '1 hour'", nativeQuery = true)
    void deleteExpired();

    // Housekeeping only: removes rows a day after their session ended, so the
    // other phone still sees expired=true for a while instead of a missing row.
    @Modifying
    @Transactional
    @Query(value = "DELETE FROM meet_location "
            + "WHERE COALESCE(expires_at, created_at + INTERVAL '1 hour') < NOW() - INTERVAL '1 day'",
            nativeQuery = true)
    void purgeLongExpired();
}