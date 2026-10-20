package com.Radius.backend.Services;

import com.Radius.backend.Bases.UserBlockRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Bases.MeetRequestRepository;
import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Entity.MeetRequest;
import com.Radius.backend.Entity.MeetLocation;
import com.Radius.backend.Forumulas.GetInnocuous;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
public class MatchService {

    private final UserRepository repo;
    private final MeetRequestRepository meetRequestRepo;
    private final MeetLocationRepository meetLocationRepo;
    private final GetInnocuous algo;

    public MatchService(
            UserRepository repo,
            UserBlockRepository blockRepo,
            MeetRequestRepository meetRequestRepo,
            MeetLocationRepository meetLocationRepo) {

        this.repo = repo;
        this.meetRequestRepo = meetRequestRepo;
        this.meetLocationRepo = meetLocationRepo;
        this.algo = new GetInnocuous(repo, blockRepo);
    }

    public List<User> findMyBestMatch(long myId) {
        User me = repo.findById(myId).orElseThrow();

        // Preserve the existing compatibility algorithm.
        List<User> candidates = algo.compatibility(me);

        // Collect users who are currently in an active meetup.
        Set<Long> usersInActiveMeetups = new HashSet<>();

        List<MeetRequest> requests = meetRequestRepo.findAll();

        for (MeetRequest request : requests) {

            String status = request.getStatus();

            // Ignore cancelled or declined meetup requests.
            if (status == null
                    || "CANCELLED".equalsIgnoreCase(status)
                    || "DECLINED".equalsIgnoreCase(status)) {
                continue;
            }

            MeetLocation location =
                    meetLocationRepo.findByMatchId(request.getMatchId());

            if (location == null || location.isCancelled()) {
                continue;
            }

            // Expired locations should no longer hide either participant.
            if (location.getCreatedAt() == null
                    || location.getCreatedAt().isBefore(
                            Instant.now().minus(1, ChronoUnit.HOURS))) {
                continue;
            }

            // Both participants must have accepted the selected location.
            boolean mutualAcceptance =
                    location.isAcceptedByA() && location.isAcceptedByB();

            if (mutualAcceptance) {
                usersInActiveMeetups.add((long) request.getRequesterId());
                usersInActiveMeetups.add((long) request.getReceiverId());
            }
        }

        // Exclude active meetup participants from scan results.
        return candidates.stream()
                .filter(user ->
                        !usersInActiveMeetups.contains((long) user.getId()))
                .toList();
    }
}