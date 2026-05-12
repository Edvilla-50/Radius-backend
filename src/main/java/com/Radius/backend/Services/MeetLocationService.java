package com.Radius.backend.Services;

import com.Radius.backend.Bases.MeetLocationRepository;
import com.Radius.backend.Entity.MeetLocation;
import org.springframework.stereotype.Service;

@Service
public class MeetLocationService {

    private final MeetLocationRepository repo;

    public MeetLocationService(MeetLocationRepository repo) {
        this.repo = repo;
    }

    public MeetLocation chooseLocation(int matchId, int chooserId,
                                       String locationId, String name, String address) {

        // If a location already exists, replace it
        MeetLocation existing = repo.findByMatchId(matchId);
        if (existing != null) {
            repo.delete(existing);
        }

        MeetLocation loc = new MeetLocation(matchId, chooserId, locationId, name, address);
        return repo.save(loc);
    }

    public MeetLocation getLocation(int matchId) {
        return repo.findByMatchId(matchId);
    }
}
