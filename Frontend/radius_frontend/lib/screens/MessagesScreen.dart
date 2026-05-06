import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'chatScreen.dart';



class MessagesScreen extends StatefulWidget {
  final int userId;
  const MessagesScreen({required this.userId});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<dynamic> matches = [];

  @override
  void initState() {
    super.initState();
    fetchMutualMatches();
  }

  Future<void> fetchMutualMatches() async {
    final response = await http.get(
      Uri.parse("https://api.radius-create.com/meet/mutual/${widget.userId}")
    );

    if (response.statusCode == 200) {
      setState(() {
        matches = jsonDecode(response.body);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Messages")),
      body: ListView.builder(
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final user = matches[index];

          return ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text(user["name"]),
            subtitle: Text("Tap to chat"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    userId: widget.userId,
                    otherUserId: user["userId"],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
