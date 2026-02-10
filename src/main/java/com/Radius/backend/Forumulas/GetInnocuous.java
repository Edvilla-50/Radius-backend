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
        double pref = me.getPerferredDistance();//pref distance of user
        double deltaLat = pref/69.00;//convert lon degrees to miles
        double deltaLon = pref / (69 * Math.cos(Math.toRadians(lat)));//convert lat degree to miles
        double MaxNorth = lat +deltaLat;//bound max distance north
        double MaxEast = lon+deltaLon;//bound max distance east
        double MaxWest = lon-deltaLon;//bound max distance west
        double MaxSouth = lat-deltaLat;//bound max distance south
        List<User> nearby = RepoSearch.findByLatBetweenAndLonBetween(MaxSouth,MaxNorth,MaxWest,MaxEast);//use JPA to make a SQL call with the pain of SQL, I love you so much vro <3
        int len = me.getStackSize();
        int[] arr = new int[len];
        for (int i = 0; i<nearby.size();i++){
            break;
        }
        return 0.0f;
    }
}
