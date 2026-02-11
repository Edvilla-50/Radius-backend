package com.Radius.backend.Forumulas;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Entity.User;

import java.util.ArrayList;
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
        List<User> trueCan = new ArrayList<>();
        for (int i = 0; i<nearby.size();i++){
            double dist = 0.0;
            dist = hs.haversine(me.getLat(),me.getLon(),nearby.get(i).getLat(),nearby.get(i).getLon());
            if(dist<=me.getPerferredDistance()){
                trueCan.add(nearby.get(i));
            }
        }
        return mergeSort(trueCan);
    }
    public static float mergeSort(List<User> truecan){
        int n = truecan.size();
        if(n<2){
            return 0.0f;
        }
        List<User> temp = new List<User>();
        mergeSortHelper(truecan, 0, n-1, temp);
    }
    public static void mergeSortHelper(List<User> turecan, int from, int to, List<User> temp){

    }
}
