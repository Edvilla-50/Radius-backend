package com.Radius.backend.Services;

import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Forumulas.GoongaGingaAlgorithm;
import org.springframework.stereotype.Service;
import java.util.List;
@Service
public class MatchService {
    private final UserRepository repo;
    private final GoongaGingaAlgorithm algo = new GoongaGingaAlgorithm();
    public MatchService(UserRepository repo){
        this.repo = repo;
    }
    public List<User> findMatches(long myId){
        User me = repo.findById(myId).orElseThrow();
        List<User> all = repo.findAll();
        return all.stream()
            .filter(u -> !u.getId().equals(myId))
            .sorted((a,b) ->
                Double.compare(
                    algo.compatibility(me,b),
                    algo.compatibility(me,a)
                )
            )
        .toList();
    }
}
