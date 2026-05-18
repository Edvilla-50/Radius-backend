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

  String? _lastLocationId; // used to detect changes

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();

    _loadSuggestions();
    _loadMessages();
    _checkSelectedLocation();

    // Poll messages + selected location
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages();
      _checkSelectedLocation();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOAD SUGGESTIONS
  // ----------------------------------------------------------
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
        SnackBar(content: Text("Error loading suggestions: $e")),
      );
    }
  }

  // ----------------------------------------------------------
  // LOAD MESSAGES
  // ----------------------------------------------------------
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
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // CHECK IF OTHER USER SELECTED A LOCATION
  // ----------------------------------------------------------
  Future<void> _checkSelectedLocation() async {
  try {
    final loc = await ApiService.getLocation(widget.matchId);
    print("DEBUG loc response: $loc"); // <-- add this
    if (loc == null) return;

    final locationId = loc["locationId"]?.toString();
    print("DEBUG locationId: $locationId, lastLocationId: $_lastLocationId");

    if (locationId == null || locationId.isEmpty) return;

    final selectedBy = (loc["userId"] as num?)?.toInt();
    print("DEBUG selectedBy: $selectedBy, myId: ${widget.userId}");

    if (selectedBy == widget.userId) return;

    if (_lastLocationId != locationId) {
      _lastLocationId = locationId;
      if (mounted) _showIncomingLocationPopup(loc);
    }
  } catch (e) {
    print("DEBUG _checkSelectedLocation error: $e"); // catch was swallowing errors
  }
}

  void _showIncomingLocationPopup(Map<String, dynamic> loc) {
    final name = loc["name"] ?? "Unknown place";
    final address = loc["address"] ?? "";

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Meet at $name?"),
        content: Text(address),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // SEND MESSAGE
  // ----------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();

    try {
      await ApiService.sendMessage(widget.matchId, widget.userId, text);
      await _loadMessages();
    } catch (_) {}
  }

  // ----------------------------------------------------------
  // SELECT LOCATION
  // ----------------------------------------------------------
  void _confirmLocationSelection(dynamic place) {
    final name = (place["name"] ?? "this place").toString();
    final address = (place["location"]?["formatted_address"] ?? "").toString();
    final fsqId = (place["fsq_place_id"] ?? "").toString();

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

              try {
                await ApiService.selectMeetLocation(
                  widget.matchId,
                  widget.userId,
                  fsqId,
                  name,
                  address,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Location selected!")),
                );
              } catch (e) {
                debugPrint("selectMeetLocation error: $e");
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = (_suggestions?["results"] is List)
        ? _suggestions["results"] as List
        : [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Suggested Places"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // ------------------ SUGGESTIONS ------------------
          Expanded(
            flex: 1,
            child: results.isEmpty
                ? const Center(
                    child: Text(
                      "No suggestions found! :(",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];

                      final fsqId =
                          (place["fsq_place_id"] ?? "").toString();
                      if (fsqId.isEmpty) return const SizedBox.shrink();

                      final name = place["name"] ?? "Unknown Place";
                      final address =
                          place["location"]?["formatted_address"] ??
                              "Address unavailable";

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(address),
                          trailing: ElevatedButton(
                            onPressed: () =>
                                _confirmLocationSelection(place),
                            child: const Text("Select"),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1),

          // ------------------ CHAT ------------------
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  color: Colors.green.shade50,
                  child: const Text(
                    "Chat",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.green),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      // FIX: same safe cast here for consistency
                      final senderId =
                          (msg["senderId"] as num?)?.toInt() ?? -1;
                      final isMe = senderId == widget.userId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.green
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg["content"] ?? "",
                            style: TextStyle(
                              color:
                                  isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ------------------ MESSAGE INPUT ------------------
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                            hintText: "Suggest a meetup spot...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: IconButton(
                          icon: const Icon(Icons.send,
                              color: Colors.white, size: 18),
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