package com.Radius.backend.Services;
import com.Radius.backend.Bases.SafetyRatingRepository;
import com.Radius.backend.Entity.SafetyRating;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Map;
@Service
public class SafetyRatingService {
    private final SafetyRatingRepository repo;

    public SafetyRatingService(SafetyRatingRepository repo){
        this.repo = repo;
    }
    public SafetyRating rateLocation(String locationId, int userId, boolean wellLit, boolean welcoming, boolean atmopshere){
        SafetyRating rating  = new SafetyRating(locationId,userId,wellLit,welcoming,atmopshere);
        return repo.save(rating);
    }

    public Map<String, Object> getSafetyScore(String locationId){
        List<SafetyRating> ratings = repo.findByLocationId(locationId);
        int total = ratings.size();
        if(total == 0){
            return Map.of(
                "locationId", locationId,
                "shield", "gray",
                "lightning", 0.0,
                "welcoming", 0.0,
                "atmosphere", 0.0,
                "totalRatings", 0
            );
        }
        long litYes = ratings.stream().filter(SafetyRating::isWellLit).count();
        long welcomeYes = ratings.stream().filter(SafetyRating::isAtmoshphere).count();
        long atmosYes = ratings.stream().filter(SafetyRating::isAtmoshphere).count();

        double lightining = litYes / (double) total;
        double welcoming = welcomeYes / (double) total;
        double atmosphere = atmosYes /(double) total;

        double max = Math.max(lightining, Math.max(welcoming, atmosphere));
        double min = Math.min(lightining, Math.min(welcoming,atmosphere));
        double range = max -min;

        String shield;

        if(total < 5 || range >= 0.5){
            shield = "gray";
        }
        else if(lightining >= 0.7 && welcoming >= 0.7 && atmosphere >= 0.7){
            shield = "green";
        }
        else if(lightining <= 0.4 && welcoming <= 0.4 && atmosphere <=0.4){
            shield = "red";
        }
        else{
            shield = "yellow";
        }
        return Map.of(
            "locationId", locationId,
            "shield", shield,
            "lighting", lightining,
            "welcoming", welcoming,
            "atmosphere", atmosphere,
            "totalRatings", total
        );
    }
}
