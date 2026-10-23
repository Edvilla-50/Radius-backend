import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:radius_frontend/enums/EmergencyType.dart';

class ApiService {
  static const String baseUrl = "https://radius-backend-0qv8.onrender.com";

  // ---------------------------
  // AUTH TOKEN
  // ---------------------------
  // Call loadToken() once at app start (before runApp / in main), saveToken()
  // right after a successful login/register, and clearToken() on logout or
  // account deletion. Until the backend starts issuing/checking tokens, no
  // token is stored and requests go out exactly as before.
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = "authToken";
  static String? _token;

  // Set this (e.g. in main.dart) to send the user back to /login when the
  // server answers 401.
  static void Function()? onUnauthorized;

  static Future<void> loadToken() async {
    _token = await _storage.read(key: _tokenKey);
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<void> clearToken() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  static Map<String, String> _headers() => {
        "Content-Type": "application/json",
        if (_token != null) "Authorization": "Bearer $_token",
      };

  static http.Response _checked(http.Response res) {
    if (res.statusCode == 401 && _token != null) {
      clearToken();
      onUnauthorized?.call();
    }
    return res;
  }

  static Future<http.Response> _get(String path) async =>
      _checked(await http.get(Uri.parse("$baseUrl$path"), headers: _headers()));

  static Future<http.Response> _post(String path, [Object? body]) async =>
      _checked(await http.post(
        Uri.parse("$baseUrl$path"),
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ));

  static Future<http.Response> _put(String path, Object? body) async =>
      _checked(await http.put(
        Uri.parse("$baseUrl$path"),
        headers: _headers(),
        body: jsonEncode(body),
      ));

  static Future<http.Response> _delete(String path) async =>
      _checked(await http.delete(Uri.parse("$baseUrl$path"), headers: _headers()));

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
    final res = await _post("/emergency/alert", {
      "userId": userId,
      "lat": lat,
      "lon": lon,
      "type": type.apiValue,
      "note": note ?? "",
    });

    if (res.statusCode != 200) {
      throw Exception("Failed to send emergency alert");
    }
  }

  // ---------------------------
  // LOCATION / CHECK-IN
  // ---------------------------

  // Manual check-in: the ONLY call that stores the user's location and makes
  // them visible to others. Must only be triggered by the user tapping SCAN.
  static Future<void> checkIn(int userId, double lat, double lon) async {
    final res = await _post("/user/$userId/check-in", {"lat": lat, "lon": lon});

    if (res.statusCode != 200) {
      throw Exception("Failed to check in");
    }
  }

  // Check-out: hides the user immediately.
  static Future<void> checkOut(int userId) async {
    final res = await _post("/user/$userId/check-out");

    if (res.statusCode != 200) {
      throw Exception("Failed to check out");
    }
  }

  // DEPRECATED: kept so other screens still compile. The server ignores it.
  // Do not use for sharing location; use checkIn instead.
  @Deprecated("Use checkIn; the server ignores this call.")
  static Future<void> updateLocation(int userId, double lat, double lon) async {
    final res = await _post("/user/$userId/location", {"lat": lat, "lon": lon});

    if (res.statusCode != 200) {
      throw Exception("Failed to update location");
    }
  }

  // ---------------------------
  // MATCHES
  // ---------------------------
  static Future<List<dynamic>> getMatches(int userId) async {
    final res = await _get("/match/$userId");

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch matches");
    }

    return jsonDecode(res.body);
  }

  // Cancels the whole meetup session (SOS / expiry). To only clear the chosen
  // place and keep the match alive, use resetMeetLocation instead.
  static Future<void> clearMeetLocation(int matchId) async {
    final res = await _post("/match/meet/clearLocation", {"matchId": matchId});

    if (res.statusCode != 200) {
      throw Exception("Failed to clear meet location and cancel session");
    }
  }

  static Future<void> sendMeetRequest(int userId, int matchId) async {
    debugPrint("SENDING MEET REQUEST userId=$userId matchId=$matchId");
    final res = await _post("/match/meet/request", {"userId": userId, "matchId": matchId});

    if (res.statusCode != 200) {
      throw Exception("Failed to send meet request");
    }
  }

  static Future<List<dynamic>> getIncoming(int userId) async {
    final res = await _get("/match/meet/incoming/$userId");

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }

    return [];
  }

  // Returns { "matchId": int, "otherUserId": int } or null
  static Future<Map<String, dynamic>?> checkMutualForUser(int userId) async {
    final res = await _get("/match/meet/mutual/find/$userId");

    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }

    return null;
  }

  // Returns { "isSender": bool }: true if this user sent the meetup request.
  static Future<Map<String, dynamic>> getMeetRole(int matchId, int userId) async {
    final res = await _get("/match/meet/role/$matchId/$userId");

    if (res.statusCode != 200) {
      throw Exception("Failed to get meetup role");
    }

    return jsonDecode(res.body);
  }

  // ---------------------------
  // USER
  // ---------------------------
  static Future<Map<String, dynamic>> getUser(int userId) async {
    final res = await _get("/user/$userId");

    if (res.statusCode != 200) {
      throw Exception("Failed to get user");
    }

    return jsonDecode(res.body);
  }

  static Future<void> updateInterests(int userId, List<int> interestIds) async {
    final res = await _put("/user/$userId/interests", interestIds);

    if (res.statusCode != 200) {
      throw Exception("Failed to update interests");
    }
  }

  static Future<void> updatePreferredDistance(int userId, double distance) async {
    final res = await _post("/user/$userId/preferred-distance", {"distance": distance});

    if (res.statusCode != 200) {
      throw Exception("Failed to update preferred distance");
    }
  }

  static Future<void> updateGhostMode(int userId, bool ghostMode) async {
    final res = await _post("/user/$userId/ghost-mode", {"ghostMode": ghostMode});

    if (res.statusCode != 200) {
      throw Exception("Failed to update ghost mode");
    }
  }

  static Future<void> updateProfileHtml(int userId, String html) async {
    final res = await _put("/user/$userId/profile-html", {"html": html});

    if (res.statusCode != 200) {
      throw Exception("Failed to update profile HTML");
    }
  }

  static Future<String> getProfileHtml(int userId) async {
    final res = await _get("/user/$userId/profile-html");

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
    final res = await _get("/interests");

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch interests");
    }

    return jsonDecode(res.body);
  }

  // ---------------------------
  // SUGGESTIONS
  // ---------------------------
  static Future<Map<String, dynamic>> getInterestSuggestions(int a, int b, int matchId) async {
    final res = await _get("/match/meet/suggestions/interests/$a/$b/$matchId");

    if (res.statusCode != 200) {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }

    if (res.body.isEmpty) {
      throw Exception("Empty response from backend");
    }

    return jsonDecode(res.body);
  }

  // The three methods below are legacy. The suggestions screen only uses
  // getInterestSuggestions. Delete these (and their server endpoints) once
  // nothing calls them. In particular getMidpoint lets a caller work out
  // another user's position from the midpoint.
  @Deprecated("Legacy; use getInterestSuggestions.")
  static Future<Map<String, dynamic>> getSyncedSuggestions(int matchId, int userA, int userB) async {
    final res = await _get("/match/meet/suggestions/sync/$matchId/$userA/$userB");

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch synced suggestions");
    }

    return jsonDecode(res.body);
  }

  @Deprecated("Legacy; remove the endpoint once unused.")
  static Future<Map<String, dynamic>> getMidpoint(int a, int b) async {
    final res = await _get("/meet/midpoint/$a/$b");

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch midpoint");
    }

    return jsonDecode(res.body);
  }

  @Deprecated("Legacy; use getInterestSuggestions.")
  static Future<Map<String, dynamic>> getSuggestions(double lat, double lon) async {
    final res = await _get("/match/meet/suggestions/$lat/$lon");

    if (res.statusCode != 200) {
      throw Exception("Failed to fetch suggestions");
    }

    return jsonDecode(res.body);
  }

  // ---------------------------
  // MESSAGING (MATCH-BASED)
  // ---------------------------
  static Future<List<dynamic>> getConversation(int matchId) async {
    final res = await _get("/messages/conversation/$matchId");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    return [];
  }

  static Future<void> sendMessage(int matchId, int senderId, String content) async {
    final res = await _post("/messages/send", {
      "matchId": matchId,
      "senderId": senderId,
      "content": content,
    });

    if (res.statusCode != 200) {
      throw Exception("Failed to send message");
    }
  }

  // NOTE: still a GET that changes state. Switch to POST together with the
  // matching change on the server.
  static Future<Map<String, dynamic>> respond(int requestId, bool accepted) async {
    final res = await _get("/match/meet/respond?requestId=$requestId&accepted=$accepted");
    return jsonDecode(res.body);
  }

  // ============================================================
  // SAFETY SYSTEM
  // ============================================================
  static Future<Map<String, dynamic>> getSafetyScore(String locationId) async {
    final res = await _get("/safety/score/$locationId");

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
    final res = await _post("/safety/rate", {
      "locationId": locationId,
      "userId": userId,
      "wellLit": wellLit,
      "welcoming": welcoming,
      "atmosphere": atmosphere,
    });

    if (res.statusCode != 200) {
      throw Exception("Failed to submit safety rating");
    }
  }

  // ============================================================
  // MEETUP LOCATION
  // ============================================================

  // Returns null ONLY when the server says nothing is selected (404 or empty
  // 200). Any other failure (500, 502 while Render wakes up, ...) throws, so
  // the screen's poll keeps its state and just retries.
  static Future<Map<String, dynamic>?> getLocation(int matchId) async {
    final res = await _get("/meet/location/$matchId");

    if (res.statusCode == 404 || (res.statusCode == 200 && res.body.isEmpty)) {
      return null;
    }
    if (res.statusCode != 200) {
      throw Exception("getLocation failed: ${res.statusCode}");
    }

    return jsonDecode(res.body);
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
    final res = await _post("/meet/select-location", {
      "matchId": matchId,
      "userId": userId,
      "locationId": locationId,
      "name": name,
      "address": address,
      "lat": lat,
      "lon": lon,
    });

    if (res.statusCode != 200) {
      throw Exception("Failed to select meet location");
    }
  }

  // locationId = the place the user was shown. The server rejects (409) if the
  // sender changed it in the meantime, so nobody confirms a place they didn't see.
  static Future<void> acceptLocation(int matchId, int userId, {String? locationId}) async {
    final res = await _post("/meet/location/accept", {
      "matchId": matchId,
      "userId": userId,
      if (locationId != null) "locationId": locationId,
    });

    if (res.statusCode != 200) {
      throw Exception("Failed to accept location");
    }
  }

  // Clears only the chosen place and both accept flags. Does NOT cancel the
  // match. Used by "Pick another" (recipient) and "Change place" (sender).
  static Future<void> resetMeetLocation(int matchId, int userId) async {
    final res = await _post("/meet/location/reset", {"matchId": matchId, "userId": userId});

    if (res.statusCode != 200) {
      throw Exception("Failed to reset meet location");
    }
  }

  static Future<Map<String, dynamic>> checkMutual(int matchId) async {
    try {
      final res = await _get("/meet/location/mutual/$matchId");

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        return jsonDecode(res.body);
      }

      // 404 / 500 / empty body: treat as pending, not expired.
      debugPrint("⚠️ /meet/location/mutual returned status ${res.statusCode}");
      return {"mutual": false, "expired": false, "sosTriggered": false};
    } catch (e) {
      debugPrint("Network error checking match mutual status: $e");
      return {"mutual": false, "expired": false, "sosTriggered": false};
    }
  }

  static Future<void> reportUser(int reporterId, int reportedUserId, String reason, String details) async {
    final res = await _post("/reports/submit", {
      "reporterId": reporterId,
      "reportedUserId": reportedUserId,
      "reason": reason,
      "details": details,
    });

    if (res.statusCode != 200) {
      throw Exception("Failed to submit report");
    }
  }

  static Future<void> blockUser(int blockerId, int blockedId) async {
    final res = await _post("/user/$blockerId/block/$blockedId");

    if (res.statusCode != 200) {
      throw Exception("Failed to block user");
    }
  }

  static Future<void> deleteAccount(int userId) async {
    final res = await _delete("/user/$userId");

    if (res.statusCode != 200) {
      throw Exception("Failed to delete account");
    }
    await clearToken();
  }
}