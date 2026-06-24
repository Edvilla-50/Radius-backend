import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:radius_frontend/enums/EmergencyType.dart';

class ApiService {
  static const String baseUrl = "https://radius-backend-0qv8.onrender.com";

  // ---------------------------
  // EMERGENCY
  // ---------------------------
  static Future<void> sendEmergency({
    required int userId,
    required EmergencyType type,
    required double lat,
    required double lon,
    String? note,
  }) async {
    final url = Uri.parse("$baseUrl/emergency/alert");

    final body = {
      "userId": userId,
      "lat": lat,
      "lon": lon,
      "type": type.apiValue,
      "note": note ?? "",
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to send emergency alert");
    }
  }

  // ---------------------------
  // LOCATION
  // ---------------------------
  static Future<void> updateLocation(int userId, double lat, double lon) async {
    final url = Uri.parse("$baseUrl/user/$userId/location");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"lat": lat, "lon": lon}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update location");
    }
  }
    static Future<Map<String, dynamic>> getSyncedSuggestions(
    int matchId,
    int userA,
    int userB,
  ) async {
    final url = Uri.parse(
      "$baseUrl/match/meet/suggestions/sync/$matchId/$userA/$userB",
    );

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch synced suggestions");
    }

    return jsonDecode(res.body);
  }
  // ---------------------------
  // MATCHES
  // ---------------------------
  static Future<List<dynamic>> getMatches(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/match/$userId"));

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch matches");
    }

    return jsonDecode(res.body);
  }

  static Future<void> clearMeetLocation(int matchId) async {
    final url = Uri.parse("$baseUrl/match/meet/clearLocation");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"matchId": matchId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to clear meet location and cancel session");
    }
  }

  static Future<void> sendMeetRequest(int userId, int matchId) async {
    debugPrint("SENDING MEET REQUEST userId=$userId matchId=$matchId");
    final url = Uri.parse("$baseUrl/match/meet/request");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userId": userId, "matchId": matchId}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to send meet request");
    }
  }

  static Future<List<dynamic>> getIncoming(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/match/meet/incoming/$userId"));

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }

    return [];
  }

  // Returns { "matchId": int, "otherUserId": int } or null
  static Future<Map<String, dynamic>?> checkMutualForUser(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/match/meet/mutual/find/$userId"));

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }

    return null;
  }

  // ---------------------------
  // USER
  // ---------------------------
  static Future<Map<String, dynamic>> getUser(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/user/$userId"));

    if (res.statusCode != 200) {
      throw Exception("Failed to get user");
    }

    return jsonDecode(res.body);
  }

  static Future<void> updateInterests(int userId, List<int> interestIds) async {
    final res = await http.put(
      Uri.parse("$baseUrl/user/$userId/interests"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(interestIds),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update interests");
    }
  }

  static Future<void> updatePreferredDistance(int userId, double distance) async {
    final res = await http.post(
      Uri.parse("$baseUrl/user/$userId/preferred-distance"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"distance": distance}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update preferred distance");
    }
  }

  static Future<void> updateGhostMode(int userId, bool ghostMode) async {
    final res = await http.post(
      Uri.parse("$baseUrl/user/$userId/ghost-mode"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"ghostMode": ghostMode}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update ghost mode");
    }
  }

  static Future<void> updateProfileHtml(int userId, String html) async {
    final res = await http.put(
      Uri.parse("$baseUrl/user/$userId/profile-html"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"html": html}),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to update profile HTML");
    }
  }

  static Future<String> getProfileHtml(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/user/$userId/profile-html"));

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch profile HTML");
    }

    final data = jsonDecode(res.body);
    return data["html"] ?? "";
  }

  // ---------------------------
  // INTERESTS
  // ---------------------------
  static Future<List<dynamic>> getAllInterests() async {
    final res = await http.get(Uri.parse("$baseUrl/interests"));

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch interests");
    }

    return jsonDecode(res.body);
  }

  // Change this method to accept matchId as the third parameter
  static Future<Map<String, dynamic>> getInterestSuggestions(int a, int b, int matchId) async {
    // Add /$matchId to the end of the URL path string
    final url = Uri.parse("$baseUrl/match/meet/suggestions/interests/$a/$b/$matchId");

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    if (res.body.isEmpty) {
      throw Exception("Empty response from backend");
    }

    return jsonDecode(res.body);
  }

    // ---------------------------
  // SUGGESTIONS / MIDPOINT
  // ---------------------------

  static Future<Map<String, dynamic>> getMidpoint(int a, int b) async {
    final res = await http.get(Uri.parse("$baseUrl/meet/midpoint/$a/$b"));

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch midpoint");
    }

    return jsonDecode(res.body);
  }

  // 🔥 THIS is the ONLY correct shared suggestions endpoint
  // (optional legacy fallback if you still use it somewhere)
  static Future<Map<String, dynamic>> getSuggestions(double lat, double lon) async {
    final res = await http.get(
      Uri.parse("$baseUrl/match/meet/suggestions/$lat/$lon"),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch suggestions");
    }

    return jsonDecode(res.body);
  }
  // ---------------------------
  // MESSAGING (MATCH-BASED)
  // ---------------------------
  static Future<List<dynamic>> getConversation(int matchId) async {
    final url = Uri.parse("$baseUrl/messages/conversation/$matchId");

    final res = await http.get(url);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }

  static Future<void> sendMessage(int matchId, int senderId, String content) async {
    final url = Uri.parse("$baseUrl/messages/send");

    final body = {
      "matchId": matchId,
      "senderId": senderId,
      "content": content,
    };

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to send message");
    }
  }

  static Future<Map<String, dynamic>> respond(int requestId, bool accepted) async {
    final res = await http.get(
      Uri.parse("$baseUrl/match/meet/respond?requestId=$requestId&accepted=$accepted"),
    );
    return jsonDecode(res.body);
  }

  // ============================================================
  // SAFETY SYSTEM
  // ============================================================
  static Future<Map<String, dynamic>> getSafetyScore(String locationId) async {
    final url = Uri.parse("$baseUrl/safety/score/$locationId");

    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception("Failed to load safety score");
    }

    return jsonDecode(res.body);
  }

  static Future<void> rateLocation(
    String locationId,
    int userId,
    bool wellLit,
    bool welcoming,
    bool atmosphere,
  ) async {
    final url = Uri.parse("$baseUrl/safety/rate");

    final body = jsonEncode({
      "locationId": locationId,
      "userId": userId,
      "wellLit": wellLit,
      "welcoming": welcoming,
      "atmosphere": atmosphere,
    });

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to submit safety rating");
    }
  }

  // ============================================================
  // MEETUP LOCATION
  // ============================================================
  static Future<Map<String, dynamic>?> getLocation(int matchId) async {
    final url = Uri.parse("$baseUrl/meet/location/$matchId");

    final res = await http.get(url);

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }

    return null;
  }

  static Future<void> selectMeetLocation(
    int matchId,
    int userId,
    String locationId,
    String name,
    String address,
    double? lat,
    double? lon,
  ) async {
    final url = Uri.parse("$baseUrl/meet/select-location");

    final body = jsonEncode({
      "matchId":    matchId,
      "userId":     userId,
      "locationId": locationId,
      "name":       name,
      "address":    address,
      "lat":        lat,
      "lon":        lon,
    });

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to select meet location");
    }
  }

  static Future<void> acceptLocation(int matchId, int userId) async {
    final url = Uri.parse("$baseUrl/meet/location/accept");

    final body = jsonEncode({
      "matchId": matchId,
      "userId": userId,
    });

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to accept location");
    }
  }

 static Future<Map<String, dynamic>> checkMutual(int matchId) async {
    final url = Uri.parse("$baseUrl/meet/location/mutual/$matchId");

    try {
      final res = await http.get(url);

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }
      
      // If the backend returns a 404, 500, or empty body, treat it as pending, not expired
      debugPrint("⚠️ Warning: /meet/location/mutual returned status ${res.statusCode}");
      return {"mutual": false, "expired": false, "sosTriggered": false};
      
    } catch (e) {
      debugPrint("Network error checking match mutual status: $e");
      // FIX: Fall back to false flags so the polling timer doesn't break instantly
      return {"mutual": false, "expired": false, "sosTriggered": false};
    }
  }
  static Future<void> reportUser(int reporterId, int reportedUserId, String reason, String details) async {
    final url = Uri.parse("$baseUrl/reports/submit");

    final res = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "reporterId": reporterId,
        "reportedUserId": reportedUserId,
        "reason": reason,
        "details": details,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to submit report");
    }
  }
  static Future<void> deleteAccount(int userId) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/user/$userId"),
      headers: {"Content-Type": "application/json"},
    );

    if (res.statusCode != 200) {
      throw Exception("Failed to delete account");
    }
  }
}