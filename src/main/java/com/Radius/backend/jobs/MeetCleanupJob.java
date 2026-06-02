package com.Radius.backend.jobs;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Bases.MeetLocationRepository;

@Component
public class MeetCleanupJob {

    private final MeetRequestRepository meetRequestRepository;
    private final MeetLocationRepository meetLocationRepository;

    public MeetCleanupJob(MeetRequestRepository meetRequestRepository,
                          MeetLocationRepository meetLocationRepository) {
        this.meetRequestRepository = meetRequestRepository;
        this.meetLocationRepository = meetLocationRepository;
    }
    @Scheduled(fixedRate = 3600000) // every hour
    @Transactional
    public void cleanupOldMeets() {
        meetRequestRepository.deleteExpired();
        meetLocationRepository.deleteExpired();
        System.out.println("Cleanup job ran: old meet requests + locations removed.");
    }
}
