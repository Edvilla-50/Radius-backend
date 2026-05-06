import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int userId;
  final int otherUserId;

  const ChatScreen({
    required this.userId,
    required this.otherUserId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List messages = [];
  final TextEditingController controller = TextEditingController();
  late Timer timer;

  @override
  void initState() {
    super.initState();
    fetchMessages();

    // Poll every second for new messages
    timer = Timer.periodic(Duration(seconds: 1), (_) {
      fetchMessages();
    });
  }

  @override
  void dispose() {
    timer.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    final url = "https://api.radius-create.com/messages/${widget.userId}/${widget.otherUserId}";
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        messages = jsonDecode(response.body);
      });
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final body = {
      "senderId": widget.userId,
      "receiverId": widget.otherUserId,
      "content": text
    };

    await http.post(
      Uri.parse("https://api.radius-create.com/messages/send"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    controller.clear();
    fetchMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final bool isMe = msg["senderId"] == widget.userId;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.orange : Colors.grey[850],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["content"],
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input bar
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Message...",
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.orange),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
