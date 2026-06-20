package com.Radius.backend.Services;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;


public final class InterestTagMapper {

    private InterestTagMapper() {}

    private static final Map<String, List<Map<String, String>>> INTEREST_TAGS = new LinkedHashMap<>();

    static {
        register("concert", tag("amenity", "concert_hall"), tag("amenity", "theatre"), tag("amenity", "nightclub"));
        register("gaming", tag("leisure", "adult_gaming_centre"), tag("shop", "games"));
        register("gym", tag("leisure", "fitness_centre"));
        register("hiking", tag("natural", "peak"), tag("tourism", "viewpoint"));
        register("reading", tag("amenity", "library"), tag("shop", "books"));
        register("sportsgame", tag("leisure", "stadium"));
        register("winetasting", tag("shop", "wine"), tag("craft", "winery"));
        register("camping", tag("tourism", "camp_site"));
        register("fishing", tag("leisure", "fishing"), tag("shop", "fishing"));
        register("cycling", tag("shop", "bicycle"));
        register("rockclimbing",
                tag(Map.of("leisure", "sports_centre", "sport", "climbing")),
                tag(Map.of("natural", "cliff", "climbing", "yes")));
        register("photography", tag("tourism", "viewpoint"), tag("tourism", "attraction")); // weak proxy
        register("cooking", tag("amenity", "community_centre")); // weak proxy, no dedicated tag
        register("coffeetasting", tag("amenity", "cafe"), tag("shop", "coffee"));
        register("foodtours", tag("amenity", "marketplace"), tag("amenity", "restaurant")); // weak proxy
        register("barbeque", tag("amenity", "bbq"), tag(Map.of("leisure", "picnic_table", "barbecue", "yes")));
        register("painting", tag("craft", "painter"), tag("shop", "art"), tag("amenity", "arts_centre"));
        register("dancing", tag("amenity", "nightclub"), tag("leisure", "dance"));
        register("livemusic",
                tag(Map.of("amenity", "bar", "live_music", "yes")),
                tag(Map.of("amenity", "pub", "live_music", "yes")),
                tag(Map.of("amenity", "restaurant", "live_music", "yes")));
        register("museumvisits", tag("tourism", "museum"));
        register("openmic", tag("amenity", "bar"), tag("amenity", "cafe")); // weak proxy
        register("soccer", tag(Map.of("leisure", "pitch", "sport", "soccer")));
        register("basketball", tag(Map.of("leisure", "pitch", "sport", "basketball")));
        register("volleyball", tag(Map.of("leisure", "pitch", "sport", "volleyball")));
        register("bowling", tag("leisure", "bowling_alley"));
        register("martialarts", tag(Map.of("leisure", "sports_centre", "sport", "martial_arts")));
        register("boardgames", tag("shop", "games"), tag("leisure", "adult_gaming_centre"));
        register("trivianights", tag("amenity", "bar"), tag("amenity", "pub")); // weak proxy
        register("movienights", tag("amenity", "cinema"));
        register("karaoke", tag("amenity", "karaoke_box"));
        register("escaperooms", tag("leisure", "escape_game"));
        register("yoga", tag(Map.of("leisure", "fitness_centre", "sport", "yoga")));
        register("meditation", tag(Map.of("leisure", "fitness_centre", "sport", "yoga"))); // weak proxy, same as yoga
        register("running", tag(Map.of("leisure", "track", "sport", "running")), tag("leisure", "park"));
        register("artsandcrafts", tag("shop", "craft"), tag("amenity", "arts_centre"));
        register("gothmusic", tag("amenity", "nightclub")); // weak proxy, OSM doesn't tag music genre
        register("religon", tag("amenity", "place_of_worship"));  // matches the spelling in the DB list
        register("religion", tag("amenity", "place_of_worship")); // safety net if spelling is fixed later
    }

    @SafeVarargs
    private static void register(String key, Map<String, String>... filters) {
        INTEREST_TAGS.put(key, List.of(filters));
    }

    private static Map<String, String> tag(String key, String value) {
        return Map.of(key, value);
    }

    private static Map<String, String> tag(Map<String, String> filter) {
        return filter;
    }

    private static String normalize(String interest) {
        return interest == null ? "" : interest.trim().toLowerCase().replaceAll("\\s+", "");
    }


    public static List<Map<String, String>> resolveTagFilters(List<String> interests) {
        List<Map<String, String>> result = new ArrayList<>();
        if (interests == null) return result;

        for (String interest : interests) {
            List<Map<String, String>> filters = INTEREST_TAGS.get(normalize(interest));
            if (filters == null) continue;

            for (Map<String, String> filter : filters) {
                if (!result.contains(filter)) {
                    result.add(filter);
                }
            }
        }
        return result;
    }
}