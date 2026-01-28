package com.Radius.backend.Forumulas;
import org.hibernate.query.sqm.tree.expression.Compatibility;

import com.Radius.backend.*;
import com.Radius.backend.Entity.*;
public class GoongaGingaAlgorithm {
    Haversine hs = new Haversine();
    public User compatibility(User radius){
        double latDistance = radius.getPerferredDistance() / 69.0; // 1 degree lat ~ 69 miles, I hate math man
        double lonDistance = radius.getPerferredDistance() / (69.0 * Math.cos(Math.toRadians(radius.getLat())));//same thing for lon
        double maxLat = radius.getLat() + latDistance;
        double minLat = radius.getLat() - latDistance;
        double maxLon = radius.getLon() + lonDistance;
        double minLon = radius.getLon() - lonDistance;
    }
}
