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
        double lon = me.getLon();//get user current longitude
        double lat = me.getLat();//get user current latitude
        double pref = me.getPerferredDistance();//
        double deltaLat = pref/69.00;
        double deltaLon = pref / (69 * Math.cos(Math.toRadians(lat)));
        double MaxNorth = lat +deltaLat;
        double MaxEast = lon+deltaLon;
        double MaxWest = lon-deltaLon;
        double MaxSouth = lat-deltaLat;
        List<User> nearby = RepoSearch.findByLatBetweenAndLonBetween(MaxSouth,MaxNorth,MaxWest,MaxEast);
        return 0.0f;
    }
}
