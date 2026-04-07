package com.Radius.backend.Tests;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.InterestEntity;
import com.Radius.backend.Entity.User;
import com.Radius.backend.Bases.InterestRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.util.Set;
@Component
public class TestSender implements CommandLineRunner {
    private final UserRepository repo;
    private final InterestRepository interestRepo;
    public TestSender(UserRepository repo,InterestRepository interestRepo){
        this.repo = repo;
        this.interestRepo = interestRepo;
    }
     @Override
    public void run(String... args) throws Exception {
         // Save interests first ✅
        InterestEntity music   = interestRepo.findByName("music").orElseGet(() -> interestRepo.save(new InterestEntity("music")));
        InterestEntity hiking  = interestRepo.findByName("hiking").orElseGet(() -> interestRepo.save(new InterestEntity("hiking")));
        InterestEntity dogs    = interestRepo.findByName("dogs").orElseGet(() -> interestRepo.save(new InterestEntity("dogs")));
        InterestEntity gaming  = interestRepo.findByName("gaming").orElseGet(() -> interestRepo.save(new InterestEntity("gaming")));
        InterestEntity cooking = interestRepo.findByName("cooking").orElseGet(() -> interestRepo.save(new InterestEntity("cooking")));
        InterestEntity painting = interestRepo.findByName("painting").orElseGet(() -> interestRepo.save(new InterestEntity("painting")));

        User eddie = new User("Eddie", 20, Set.of(music, hiking, dogs));
        eddie.setLat(31.7619);
        eddie.setLon(-106.4850);
        eddie.setPerferredDistance(10.0);

        User alice = new User("Alice", 21, Set.of(music, dogs, gaming));
        alice.setLat(31.7700);
        alice.setLon(-106.4900);

        User bob = new User("Bob", 22, Set.of(cooking, painting));
        bob.setLat(31.7650);
        bob.setLon(-106.4800);

        repo.save(eddie);
        repo.save(alice);
        repo.save(bob);

        System.out.println("Fake data seeded!");
    }
}
