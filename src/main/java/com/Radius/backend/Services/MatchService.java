package com.Radius.backend.Services;

import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Forumulas.GetInnocuous;
import org.springframework.stereotype.Service;
@Service
public class MatchService {

    private final UserRepository repo;
    private final GetInnocuous algo;

    public MatchService(UserRepository repo){
        this.repo = repo;
        this.algo = new GetInnocuous(repo);
    }

    public float findMyBestMatch(long myId){
        User me = repo.findById(myId).orElseThrow();
        return algo.compatibility(me);
    }
}
