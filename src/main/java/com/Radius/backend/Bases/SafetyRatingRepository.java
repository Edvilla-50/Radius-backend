package com.Radius.backend.Bases;
import com.Radius.backend.Entity.SafetyRating;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
public interface SafetyRatingRepository extends JpaRepository<SafetyRating,Long>{
    List<SafetyRating> findByLocationId(String locationId);
}
