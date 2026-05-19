import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import 'MeetupMapScreen.dart';
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

  bool _initialCheckDone = false;
  bool _waitingForRecipient = false;

  // _navigated is the single source of truth. Once true, nothing touches the
  // server or the navigator again. Set it synchronously before any await.
  bool _navigated = false;
  bool _popupShown = false;

  // True when this user was the one who chose the location.
  bool _iAmChooser = false;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
    _loadMessages();
    _checkSelectedLocation();

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_navigated) return;
      _loadMessages();
      _checkSelectedLocation();
      _checkMutualAcceptance();
    });
  }

  @override
  void dispose() {
    debugPrint("DEBUG SuggestionsScreen disposed (matchId=${widget.matchId})");
    _pollTimer?.cancel();
    _pollTimer = null;
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Navigation
  // -------------------------------------------------------------------------

  Future<void> _goToMeetupMap(String name, String address) async {
    // Flip synchronously first — any in-flight async callbacks will bail after
    // their await when they re-check this flag.
    if (_navigated) return;
    _navigated = true;

    _pollTimer?.cancel();
    _pollTimer = null;

    // Only the chooser clears the DB row. If the recipient cleared it first,
    // the chooser's next checkMutual would see mutual:false and get stuck.
    // We await so the row is only deleted after polling has fully stopped.
    if (_iAmChooser) {
      try {
        await ApiService.clearMeetLocation(widget.matchId);
      } catch (e) {
        debugPrint("clearMeetLocation error: $e");
      }
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MeetupMapScreen(
          userId: widget.userId,
          otherUserId: widget.otherUserId,
          placeName: name,
          placeAddress: address,
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Data loading
  // -------------------------------------------------------------------------

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
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
    } catch (_) {}
  }

  // -------------------------------------------------------------------------
  // Polling logic
  // -------------------------------------------------------------------------

  Future<void> _checkSelectedLocation() async {
    if (_navigated) return;

    try {
      final loc = await ApiService.getLocation(widget.matchId);
      if (_navigated) return; // re-check after await

      if (loc == null) return;

      final chooserId = (loc["chooserId"] as num?)?.toInt();
      final name = (loc["name"] ?? "Unknown place").toString();
      final address = (loc["address"] ?? "").toString();

      final acceptedByA = loc["acceptedByA"] == true;
      final acceptedByB = loc["acceptedByB"] == true;

      if (chooserId == null) return;

      final iAmChooser = chooserId == widget.userId;
      final iAccepted = iAmChooser ? acceptedByA : acceptedByB;

      // Track whether this user is the chooser so _goToMeetupMap knows
      // who should clear the location.
      _iAmChooser = iAmChooser;

      // First poll: sync state only, do not show popup yet
      if (!_initialCheckDone) {
        _initialCheckDone = true;
        if (iAmChooser && !iAccepted) {
          if (mounted) setState(() => _waitingForRecipient = true);
        }
        return;
      }

      // I already accepted — keep UI consistent
      if (iAccepted) {
        if (!iAmChooser && _waitingForRecipient) {
          if (mounted) setState(() => _waitingForRecipient = false);
        }
        return;
      }

      // I'm the chooser → show waiting banner
      if (iAmChooser) {
        if (!_waitingForRecipient) {
          if (mounted) setState(() => _waitingForRecipient = true);
        }
        return;
      }

      // I'm the recipient and haven't accepted → show popup ONCE
      if (!_popupShown) {
        _popupShown = true;
        _showIncomingLocationPopup(name, address);
      }
    } catch (e) {
      debugPrint("_checkSelectedLocation error: $e");
    }
  }

  Future<void> _checkMutualAcceptance() async {
    if (_navigated) return;

    try {
      final res = await ApiService.checkMutual(widget.matchId);
      if (_navigated) return; // re-check after await

      debugPrint("DEBUG Checkmutual: $res");

      if (res["mutual"] == true) {
        final name = (res["name"] ?? "Meetup spot").toString();
        final address = (res["address"] ?? "").toString();
        if (mounted) await _goToMeetupMap(name, address);
      }
    } catch (e) {
      debugPrint("_checkMutualAcceptance error: $e");
    }
  }

  // -------------------------------------------------------------------------
  // UI actions
  // -------------------------------------------------------------------------

  void _showIncomingLocationPopup(String name, String address) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Meet at $name?"),
        content: Text(
          address.isNotEmpty ? address : "Your match chose a meetup spot.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService.acceptLocation(widget.matchId, widget.userId);
                if (mounted) setState(() => _waitingForRecipient = false);
              } catch (e) {
                debugPrint("acceptLocation error: $e");
              }
            },
            child: const Text("Let's go!"),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    _msgController.clear();
    try {
      await ApiService.sendMessage(widget.matchId, widget.userId, text);
      await _loadMessages();
    } catch (_) {}
  }

  void _confirmLocationSelection(dynamic place) {
    final name = (place["name"] ?? "this place").toString();
    final address =
        (place["location"]?["formatted_address"] ?? "").toString();
    final fsqId = (place["fsq_place_id"] ?? "").toString();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Choose $name?"),
        content: Text(address),
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
                _iAmChooser = true;
                setState(() => _waitingForRecipient = true);
              } catch (e) {
                debugPrint("selectMeetLocation error: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to select location: $e")),
                  );
                }
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

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
          if (_waitingForRecipient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.green.shade100,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Waiting for them to accept...",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

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
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(address),
                          trailing: ElevatedButton(
                            onPressed: _waitingForRecipient
                                ? null
                                : () => _confirmLocationSelection(place),
                            child: const Text("Select"),
                          ),
                        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.green.shade50,
                  child: const Text(
                    "Chat",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final senderId =
                          (msg["senderId"] as num?)?.toInt() ?? -1;
                      final isMe = senderId == widget.userId;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Colors.green
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            msg["content"] ?? "",
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
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
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.green,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 18,
                          ),
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