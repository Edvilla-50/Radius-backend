package com.Radius.backend.Bases;

import com.Radius.backend.Entity.MeetLocation;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MeetLocationRepository extends JpaRepository<MeetLocation, Long> {

    MeetLocation findByMatchId(int matchId);
}
