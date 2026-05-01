  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:radius_frontend/enums/EmergencyType.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8080";

  static Future<void> sendEmergency({
    required int userId,
    required EmergencyType type,
    required double lat,
    required double lon,
    String? note,
  }) async {
    final url = Uri.parse("$baseUrl/emergency/alert");

    final body = {
      "userId": userId.toString(),
      "lat": lat.toString(),
      "lon": lon.toString(),
      "type": type.apiValue,
      "note": note ?? "",
    };

    final response = await http.post(url, body: body);

    if (response.statusCode != 200) {
      throw Exception("Failed to send emergency alert");
    }
  }

  static Future<void> updateLocation(int userId, double lat, double lon) async {
    final response = await http.post(
      Uri.parse("$baseUrl/user/$userId/location"),
      headers: {'Content-type': 'application/json'},
      body: jsonEncode({'lat':lat, 'lon': lon})
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update location");
    }
  } 

  static Future<List<dynamic>> getMatches(int userId) async {
    final url = Uri.parse('$baseUrl/match/$userId');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch matches");
    }

    return jsonDecode(response.body);
  }


  static Future<void> sendMeetRequest(int userId, int matchId) async {
    print("SENDING MEET REQUEST: userId=$userId matchId=$matchId");
    final url = Uri.parse('$baseUrl/match/meet/request');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'matchId': matchId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send meet request');
    }
  }

    static Future<Map<String, dynamic>> getUser(int userId) async {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get user');
      }
  }

  static Future<void> updateInterests(int userId, List<int> interestIds) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/$userId/interests'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(interestIds),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update interests');
    }
  }
  static Future<List<dynamic>> getAllInterests() async {
  final response = await http.get(Uri.parse('$baseUrl/interests'));
  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to get interests');
    }
  }
  static Future<void> updateProfileHtml(int userId, String html) async {
    final response = await http.put(
      Uri.parse('$baseUrl/user/$userId/profile-html'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'html': html}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  static Future<Map<String, dynamic>> respond(int requestId, bool accepted) async {
    final res = await http.get(
      Uri.parse("$baseUrl/match/meet/respond?requestId=$requestId&accepted=$accepted")
    );
    return jsonDecode(res.body);
  }

  static Future<bool> checkMutual(int a, int b) async {
    final res = await http.get(
      Uri.parse("$baseUrl/match/meet/mutual/$a/$b"),
    );
    return jsonDecode(res.body);
  }


  Future<Map<String, dynamic>> getMidpoint(int a, int b) async {
    final res = await http.get(Uri.parse("$baseUrl/meet/midpoint/$a/$b"));
    return jsonDecode(res.body);
  }

  Future<dynamic> getSuggestions(double lat, double lon) async {
    final res = await http.get(
      Uri.parse("$baseUrl/match/meet/suggestions/$lat/$lon")
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> getInterestSuggestions(int a, int b) async {
    final url = Uri.parse("$baseUrl/match/meet/suggestions/interests/$a/$b");

    final res = await http.get(url);

    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");

    if (res.statusCode == 200) {
      if (res.body.isEmpty) {
        throw Exception("Empty response from backend");
      }

      return jsonDecode(res.body);
    } else {
      throw Exception("Backend error ${res.statusCode}: ${res.body}");
    }
  }
  static Future<List<dynamic>> getIncoming(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/match/meet/incoming/$userId"));
    if (res.statusCode == 200 && res.body.isNotEmpty) {
      return jsonDecode(res.body);
    }
    return [];
  }
  static Future<int?> checkMutualForUser(int userId) async {
    final url = Uri.parse("$baseUrl/match/meet/mutual/find/$userId");
    final response = await http.get(url);
    print("MUTUAL STATUS CODE: ${response.statusCode}"); // 👈
    print("MUTUAL BODY: ${response.body}");    

    if (response.statusCode == 200) {
      return int.parse(response.body);
    }
    return null;
  }
  static Future<List<dynamic>> getConversation(int a, int b) async {
    final url = "$baseUrl/messages/conversation/$a/$b";
    print("FETCHING CONVERSATION: $url"); // 👈
    final res = await http.get(Uri.parse(url));
    print("CONVERSATION STATUS: ${res.statusCode}"); // 👈
    print("CONVERSATION BODY: ${res.body}"); // 👈
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
}

  static Future<void> sendMessage(int senderId, int receiverId, String content) async {
    await http.post(
      Uri.parse("$baseUrl/messages/send"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senderId': senderId, 'receiverId': receiverId, 'content': content}),
    );
  }
}
