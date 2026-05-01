import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import 'dart:async';

class SuggestionsScreen extends StatefulWidget {
  final int userId;
  final int otherUserId;

  const SuggestionsScreen({
    super.key,
    required this.userId,
    required this.otherUserId,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  bool _loading = true;
  dynamic _suggestions;
  List<dynamic> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadMessages();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) => _loadMessages());
    print("POLLING MESSAGES...");
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose(); // 👈 was _msgContoller (typo)
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final res = await ApiService().getInterestSuggestions(
        widget.userId,
        widget.otherUserId,
      );
      setState(() {
        _suggestions = res;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading suggestions: $e')),
      );
    }
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getConversation(widget.userId, widget.otherUserId); 
      setState(() => _messages = msgs);
      WidgetsBinding.instance.addPostFrameCallback((_) { 
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if(text.isEmpty){
      return;
    }
    _msgController.clear();
    setState(() {
      _messages.add({
        'senderId': widget.userId,
        'receiverId': widget.otherUserId,
        'content': text,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
        });
    });
    try{
      await ApiService.sendMessage(widget.userId, widget.otherUserId, text);
      await _loadMessages();
    }catch(e){
      print('error sending messages');
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = (_suggestions?["results"] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Suggested Places"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // Suggestions list - top half
          Expanded(
            flex: 1,
            child: results.isEmpty
                ? const Center(
                    child: Text("No suggestions found! :(", style: TextStyle(fontSize: 18)),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      final name = place['name'] ?? "Unknown Place";
                      final address = place["location"]?["formatted_address"] ?? "No Address";
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.place, color: Colors.blue),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(address),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // Chat section - bottom half
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.green.shade50,
                  child: const Text(
                    "Chat",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      print("MSG: ${msg['content']}, senderId: ${msg['senderId']} (${msg['senderId'].runtimeType}), myId: ${widget.userId} (${widget.userId.runtimeType}), isMe: ${msg['senderId'] == widget.userId}"); // 
                      final isMe = msg['senderId'] == widget.userId;
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg['content'] ?? '',
                            style: TextStyle(color: isMe ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                            hintText: "Suggest a meetup spot...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 18),
                          onPressed: _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}