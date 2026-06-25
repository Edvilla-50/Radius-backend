package com.Radius.backend.Forumulas;
import com.Radius.backend.Aspects.*;
import com.Radius.backend.Bases.UserBlockRepository;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Data_Structres.TraitStack.TraitPopResult;
import com.Radius.backend.Entity.User;

import java.util.ArrayList;
import java.util.List;
public class GetInnocuous {

    Haversine hs = new Haversine();
    private final UserRepository RepoSearch;
    private final UserBlockRepository blockRepo; 
    public GetInnocuous(UserRepository RepoSearch, UserBlockRepository blockRepo){
        this.RepoSearch = RepoSearch;
        this.blockRepo = blockRepo;
    }

    public static double score(int position, int stackSize) {
        return (double)(stackSize - position) / stackSize;
    }

    public List <User> compatibility(User me) {
        if(me.isGhostMode()){
            return new ArrayList<>();
        }
        double lon = me.getLon();
        double lat = me.getLat();
        double pref = me.getPerferredDistance();
        double deltaLat = pref/69.00;
        double deltaLon = pref / (69 * Math.cos(Math.toRadians(lat)));
        double MaxNorth = lat + deltaLat;
        double MaxEast = lon + deltaLon;
        double MaxWest = lon - deltaLon;
        double MaxSouth = lat - deltaLat;
        List<User> nearby = RepoSearch.findByLatBetweenAndLonBetween(MaxSouth, MaxNorth, MaxWest, MaxEast);

        List<Long> blockedByMe = blockRepo.findByBlockerId(me.getId())
            .stream().map(b -> b.getBlockedId()).toList();
        List<Long> blockedMe = blockRepo.findByBlockedId(me.getId())
            .stream().map(b -> b.getBlockerId()).toList();

        List<User> trueCan = new ArrayList<>();
        for (int i = 0; i < nearby.size(); i++) {
            User u = nearby.get(i);
            double dist = hs.haversine(me.getLat(), me.getLon(), u.getLat(), u.getLon());
            boolean withinRange = dist <= me.getPerferredDistance();
            boolean notMe = !u.getId().equals(me.getId());
            boolean notGhost = !u.isGhostMode();
            boolean notBlocked = !blockedByMe.contains(u.getId()) && !blockedMe.contains(u.getId());

            if (withinRange && notMe && notGhost && notBlocked) {
                trueCan.add(u);
            }
        }

        me.pushAllIntrestsToStack();
        for (User u : trueCan) {
            u.pushAllIntrestsToStack();
            u.resetScore();
        }
        NRank(trueCan, me);
        sort(trueCan);
        System.out.println("User " + me.getName() + " interests loaded = " + me.getInterests().size());
        return trueCan;
    }

    public static void NRank(List<User> truecan, User me){
        List<TraitPopResult> meTrait = new ArrayList<>();
        int i = me.getStackSize();
        int size = me.getStackSize();
        while(i != 0){
            meTrait.add(me.popOnStack());
            i--;
        }
        double maxScore = 0.0;
        for(int x = 0; x < size; x++){
            maxScore += score(x, size);
        }
        System.out.println("size=" + size + " maxScore=" + maxScore);
        for(int u = 0; u < truecan.size(); u++){
            List<TraitPopResult> oppTrait = new ArrayList<>();
            int t = truecan.get(u).getStackSize();
            int oppsize = t;
            while(t != 0){
                oppTrait.add(truecan.get(u).popOnStack());
                t--;
            }
            double total = 0.0;
            t = 0;
            while(t < size){
                int t2 = 0;
                while(t2 < oppsize){
                    if(meTrait.get(t).trait().equals(oppTrait.get(t2).trait())){
                        truecan.get(u).setScore(score(oppTrait.get(t2).position(), oppsize));
                        total += score(t, size); 
                        break;
                    }
                    t2++;
                }
                t++;
            }
            truecan.get(u).setScore(total / maxScore);
        }
    }

    void sort(List<User> truecan){
        int n = truecan.size();
        for(int i = 1; i < n; i++){
            User key = truecan.get(i);
            int j = i - 1;
            while(j >= 0 && truecan.get(j).getScore() < key.getScore()){
                truecan.set(j+1, truecan.get(j));
                j = j - 1; 
            }
            truecan.set(j+1, key);
        }
    }
}