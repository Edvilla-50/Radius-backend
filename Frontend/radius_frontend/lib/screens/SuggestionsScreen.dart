import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import 'dart:async';

class SuggestionsScreen extends StatefulWidget {
  final int userId;
  final int otherUserId;
  final int matchId;

  const SuggestionsScreen({
    super.key,
    required this.userId,
    required this.otherUserId,
    required this.matchId,
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
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestions() async {
    try {
      final res = await ApiService.getInterestSuggestions(
        widget.userId,
        widget.otherUserId,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading suggestions: $e')),
      );
    }
  }

  Future<void> _loadMessages() async {
    try {
      final msgs = await ApiService.getConversation(widget.matchId);
      if (!mounted) return;
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
    if (text.isEmpty) return;
    _msgController.clear();
    try {
      await ApiService.sendMessage(widget.matchId, widget.userId, text);
      await _loadMessages();
    } catch (e) {
      print('error sending message: $e');
    }
  }

  Widget _buildShield(String shield) {
    switch (shield) {
      case "green":
        return const Icon(Icons.shield, color: Colors.green, size: 22);
      case "yellow":
        return const Icon(Icons.shield, color: Colors.orange, size: 22);
      case "red":
        return const Icon(Icons.shield, color: Colors.red, size: 22);
      default:
        return const Icon(Icons.shield, color: Colors.grey, size: 22);
    }
  }

  void _confirmLocationSelection(dynamic place) {
    final name = (place["name"] ?? "this place").toString();
    final address = (place["location"]?["formatted_address"] ?? "").toString();
    final fsqId = (place["fsq_id"] ?? "").toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Choose $name?"),
        content: Text("Do you want to meet at:\n$address"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              await ApiService.selectMeetLocation(
                widget.matchId,
                widget.userId,
                fsqId,
                name,
                address,
              );

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Location selected!")),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
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

                      final fsqId = (place["fsq_id"] ?? "").toString();
                      if (fsqId.isEmpty) return const SizedBox.shrink();

                      final name = (place["name"] ?? "Unknown Place").toString();
                      final location = place["location"] as Map<String, dynamic>?;
                      final address = (location?["formatted_address"] ?? "Address unavailable").toString();

                      return FutureBuilder(
                        future: ApiService.getSafetyScore(fsqId),
                        builder: (context, snapshot) {
                          String shield = "gray";

                          if (snapshot.connectionState == ConnectionState.done &&
                              snapshot.hasData &&
                              snapshot.data is Map<String, dynamic>) {
                            final data = snapshot.data as Map<String, dynamic>;
                            shield = (data["shield"] ?? "gray").toString();
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: ListTile(
                              leading: _buildShield(shield),
                              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(address),
                              trailing: ElevatedButton(
                                onPressed: () => _confirmLocationSelection(place),
                                child: const Text("Select"),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

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
                      final isMe = (msg['senderId'] as num).toInt() == widget.userId;

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
                            (msg['content'] ?? '').toString(),
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
