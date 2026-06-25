package com.Radius.backend.Services;

import com.Radius.backend.Bases.UserBlockRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Forumulas.GetInnocuous;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class MatchService {

    private final UserRepository repo;
    private final GetInnocuous algo;

    public MatchService(UserRepository repo, UserBlockRepository blockRepo) {
        this.repo = repo;
        this.algo = new GetInnocuous(repo, blockRepo);
    }

    public List<User> findMyBestMatch(long myId) {
        User me = repo.findById(myId).orElseThrow();
        return algo.compatibility(me);
    }
}