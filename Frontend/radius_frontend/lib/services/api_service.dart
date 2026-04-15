import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService{
  static const String baseUrl = "http://10.0.2.2:8080";
  //get matches for user
  static Future<List<dynamic>> getMatches(int userId)async{//signature, returns a list via json
    final response = await http.get(Uri.parse('$baseUrl/match/$userId'));//calls to backend
    if(response.statusCode == 200){//json status code for succesful fetch
      return jsonDecode(response.body);
    }else{
      throw Exception('Could not get matches');//error
    }
  }
  //update location
  static Future <void> updateLocation(int userId, double lat, double lon) async{//signature
    final response = await http.post(Uri.parse('$baseUrl/user/$userId/location'),//post to update rather than get to fetch
    headers: {'Content-type': 'application/json'},//format json objects
    body: jsonEncode({'lat': lat, 'lon': lon}),
    );
    if(response.statusCode != 200){//error
      throw Exception("Could not update location");
    }
  }
  static Future <void> createUser(Map<String, dynamic> userData) async{//signature
    final response = await http.post(Uri.parse('$baseUrl/user'),//post to update rather than get to fetch
    headers: {'Content-type': 'application/json'},//format json objects
    body: jsonEncode(userData),
    );
    if(response.statusCode != 200){//error
      throw Exception("Could not create user");
    }
  }
}