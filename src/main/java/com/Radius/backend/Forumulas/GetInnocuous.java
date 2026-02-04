package com.Radius.backend.Forumulas;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;

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
        double deltaLon = pref/(69*Math.cos(lat));
        double MaxNorth = lat +deltaLat;
        double MaxEast = lon+deltaLon;
        double maxWest = lon-deltaLon;
        double maxSouth = lon-deltaLat;
    }
}
