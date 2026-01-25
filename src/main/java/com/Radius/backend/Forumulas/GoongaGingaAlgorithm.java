package com.Radius.backend.Forumulas;
import com.Radius.backend.*;
import com.Radius.backend.Entity.*;
public class GoongaGingaAlgorithm {
    public void Algorithm(User one, User two){
        Haversine hs = new Haversine();
        double distance = hs.haversine(one.getLat(),one.getLon(),two.getLat(),two.getLon());
    }
}
