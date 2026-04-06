package com.Radius.backend.Forumulas;
import com.Radius.backend.Aspects.*;
import com.Radius.backend.Bases.UserRepository;
import com.Radius.backend.Data_Structres.TraitStack.TraitPopResult;
import com.Radius.backend.Entity.User;

import java.util.ArrayList;
import java.util.List;
public class GetInnocuous {

    Haversine hs = new Haversine();
    private final UserRepository RepoSearch;
    public GetInnocuous(UserRepository RepoSearch){
        this.RepoSearch = RepoSearch;
    }

    public static double score(int position, int stackSize) {//sigmoid more like sigma am I right fellas?
        return (double)(stackSize - position) / stackSize;
    }
    /**
 * Returns most compatibale user
     * Higher score = more compatible
     */
    public List <User> compatibility(User me) {
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
                trueCan.add(nearby.get(i));//append compatiable user via distance, add to list
            }
        }
        me.pushAllIntrestsToStack();
        for (User u : trueCan) {
            u.pushAllIntrestsToStack();
        }
        NRank(trueCan, me);
        sort(trueCan);
        return trueCan;
    }
    public static void NRank(List<User> truecan, User me){//void since we pass by refrence
        List<TraitPopResult> meTrait = new ArrayList<>();
        int i=me.getStackSize();
        int size = me.getStackSize();//it will change as we pop so we need it early on
        while(i!=0){
            meTrait.add(me.popOnStack());//metrait has all user traits from most important at front and least at back
            i--;
        }
        for(int u = 0; u<truecan.size();u++){
            List<TraitPopResult> oppTrait = new ArrayList<>();
            int t = truecan.get(u).getStackSize();//get canidate user stack size
            int oppsize = t;//store opppttait stack before it is modified
            while(t!=0){
                oppTrait.add(truecan.get(u).popOnStack());
                t--;
            }
            t=0;
            while(t<size){
                int t2=0;
                while(t2<oppsize){
                    if(meTrait.get(t).trait().equals(oppTrait.get(t2).trait()))
                        truecan.get(u).setScore(score(oppTrait.get(t2).position(), oppsize));
                    t2++;
                }
                t++;
            }
       }
    }
    void sort(List<User> truecan){
        int n = truecan.size();
        for(int i = 1; i< n; i++){
            User key = truecan.get(i);
            int j = i-1;
            while(j >= 0 && truecan.get(j).getScore() < key.getScore()){
                truecan.set(j+1,truecan.get(j));
                j=j-1; 
            }
            truecan.set(j+1,key);
        }
    }
}