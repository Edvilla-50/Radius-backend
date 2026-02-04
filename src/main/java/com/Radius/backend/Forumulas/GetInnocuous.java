package com.Radius.backend.Forumulas;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;
import java.util.List;

public class GetInnocuous {

    Haversine hs = new Haversine();
    private final UserRepository RepoSearch;
    public GetInnocuous(UserRepository RepoSearch){
        this.RepoSearch = RepoSearch;
    }
    /**
 * Returns most compatibale user
     * Higher score = more compatible
     */
    public float compatibility(User me) {
        double lon = me.getLon();
        double lat = me.getLat();
        double pref = me.getPerferredDistance();
        double deltaLat = pref/69.00;
        double deltaLon = pref / (69 * Math.cos(Math.toRadians(lat)));
        double MaxNorth = lat +deltaLat;
        double MaxEast = lon+deltaLon;
        double maxWest = lon-deltaLon;
        double maxSouth = lat-deltaLat;
        double distanceNorth = hs.haversine(lat, lon, MaxNorth, lon);
        double distanceEast  = hs.haversine(lat, lon, lat, MaxEast);
        double distanceWest = hs.haversine(lat, lon, lat, maxWest);
        double distanceSouth = hs.haversine(lat, lon, maxSouth, lon);
        List<User> canidates = RepoSearch.findByLatBetweenAndLonBetween(distanceSouth,distanceNorth, distanceWest,distanceEast);

    }
}
