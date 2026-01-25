package com.Radius.backend.Forumulas;

public class Haversine {
   private static final double EARTH_RADIUS_MILES = 3958.8; // Earth's radius in miles
   public double haversine(double lat1, double lon1, double lat2, double lon2) {
       // Convert degrees to radians
       double dLat = Math.toRadians(lat2 - lat1);
       double dLon = Math.toRadians(lon2 - lon1);
       lat1 = Math.toRadians(lat1);
       lat2 = Math.toRadians(lat2);
       // Apply Haversine formula
       double a = Math.pow(Math.sin(dLat / 2), 2) +
                  Math.cos(lat1) * Math.cos(lat2) *
                  Math.pow(Math.sin(dLon / 2), 2);
       double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
       return EARTH_RADIUS_MILES * c;
   }
}
