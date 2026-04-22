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
    final url = Uri.parse("$baseUrl/match/$userId");

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch matches");
    }

    return jsonDecode(response.body);
  }

  static Future<void> sendMeetRequest(int userId, int matchId) async{
    final url = Uri.parse('$baseUrl/meet/request');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'matchId': matchId,
      }),
    );
    if(response.statusCode != 200){
      throw Exception('Failed to send meet request');
    }
  }
}
