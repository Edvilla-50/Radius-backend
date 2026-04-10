package com.Radius.backend.Tests;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.InterestEntity;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Bases.InterestRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.List;
@Component
public class TestSender implements CommandLineRunner {
    private final UserRepository repo;
    private final InterestRepository interestRepo;
    public TestSender(UserRepository repo, InterestRepository interestRepo){
        this.repo = repo;
        this.interestRepo = interestRepo;
    }

    @Override
    public void run(String... args) throws Exception {
        if(repo.count() == 0){
            // Interests
            InterestEntity concert     = interestRepo.findByName("concert").orElseGet(() -> interestRepo.save(new InterestEntity("concert")));
            InterestEntity gaming      = interestRepo.findByName("gaming").orElseGet(() -> interestRepo.save(new InterestEntity("gaming")));
            InterestEntity gym         = interestRepo.findByName("gym").orElseGet(() -> interestRepo.save(new InterestEntity("gym")));
            InterestEntity hiking      = interestRepo.findByName("hiking").orElseGet(() -> interestRepo.save(new InterestEntity("hiking")));
            InterestEntity reading     = interestRepo.findByName("reading").orElseGet(() -> interestRepo.save(new InterestEntity("reading")));
            InterestEntity sportsGame  = interestRepo.findByName("sportsGame").orElseGet(() -> interestRepo.save(new InterestEntity("sportsGame")));
            InterestEntity wineTesting = interestRepo.findByName("wineTesting").orElseGet(() -> interestRepo.save(new InterestEntity("wineTesting")));

            // Eddie - the query user (hiking, gaming, reading)
            User eddie = new User("Eddie", 20, List.of(hiking, gaming, reading));
            eddie.setLat(31.7619);
            eddie.setLon(-106.4850);
            eddie.setPerferredDistance(10.0);

            // Should rank 1st - shares all 3 interests
            User carlos = new User("Carlos", 22, List.of(hiking, gaming, reading));
            carlos.setLat(31.7630);
            carlos.setLon(-106.4860);

            // Should rank 2nd - shares hiking + gaming
            User alice = new User("Alice", 21, List.of(hiking, gaming, concert));
            alice.setLat(31.7700);
            alice.setLon(-106.4900);

            // Should rank 3rd - shares only reading
            User maria = new User("Maria", 23, List.of(reading, gym, wineTesting));
            maria.setLat(31.7650);
            maria.setLon(-106.4820);

            // Should score 0 - no shared interests, nearby
            User bob = new User("Bob", 22, List.of(concert, wineTesting));
            bob.setLat(31.7650);
            bob.setLon(-106.4800);

            // Should NOT appear - outside radius (New York)
            User farAway = new User("FarAway", 25, List.of(hiking, gaming, reading));
            farAway.setLat(40.7128);
            farAway.setLon(-74.0060);

            // Should score 0 - no shared interests, nearby
            User sarah = new User("Sarah", 24, List.of(sportsGame, gym));
            sarah.setLat(31.7610);
            sarah.setLon(-106.4840);

            repo.save(eddie);
            repo.save(carlos);
            repo.save(alice);
            repo.save(maria);
            repo.save(bob);
            repo.save(farAway);
            repo.save(sarah);

            System.out.println("Fake data seeded!");
        }
    }
}