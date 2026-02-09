package com.Radius.backend.Bases;
import com.Radius.backend.Entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    List<User> findByLatBetweenAndLonBetween(
        double minLat,
        double maxLat,
        double minLon,
        double maxLon
    );
}
