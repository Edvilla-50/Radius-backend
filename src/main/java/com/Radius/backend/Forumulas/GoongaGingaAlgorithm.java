package com.Radius.backend.Forumulas;

import com.Radius.backend.Entity.User;

public class GoongaGingaAlgorithm {

    Haversine hs = new Haversine();

    /**
     * Returns a compatibility score between two users.
     * Higher score = more compatible
     */
    public double compatibility(User me, User other) {
        double distance = hs.haversine(me.getLat(), me.getLon(), other.getLat(), other.getLon());

        // If the distance is beyond the other's preferred distance, score = 0
        if (distance > other.getPerferredDistance()) {
            return 0;
        }

        // Simple distance-based score: closer is better
        double score = other.getPerferredDistance() - distance;

        return score;
    }
}
