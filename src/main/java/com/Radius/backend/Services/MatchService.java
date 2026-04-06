package com.Radius.backend.Services;

import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Forumulas.GetInnocuous;
import org.springframework.stereotype.Service;
import java.util.ArrayList;
import java.util.List;
@Service
public class MatchService {

    private final UserRepository repo;
    private final GetInnocuous algo;

    public MatchService(UserRepository repo){
        this.repo = repo;
        this.algo = new GetInnocuous(repo);
    }

    public List<User> findMyBestMatch(long myId){
        User me = repo.findById(myId).orElseThrow();
        return algo.compatibility(me);
    }
}
