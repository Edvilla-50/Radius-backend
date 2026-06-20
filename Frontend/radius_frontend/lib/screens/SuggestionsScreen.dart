import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ApiService.dart';
import '../state/AppState.dart';
import '../screens/EmergencyScreen.dart';
import 'MeetupMapScreen.dart';
import 'dart:async';

class SuggestionsScreen extends StatefulWidget {
  final int otherUserId;
  final int matchId;

  const SuggestionsScreen({
    super.key,
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

  int? userId;

  bool _initialCheckDone = false;
  bool _waitingForRecipient = false;
  bool _navigated = false; 
  bool _popupShown = false;
  bool _iAmChooser = false;

  double? _selectedPlaceLat;
  double? _selectedPlaceLon;
  bool _locationEverExisted = false;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  Timer? _expireTimer;

  @override
  void initState() {
    super.initState();
    _initScreenData();

    _expireTimer = Timer(const Duration(hours: 1), () {
      _handleSessionExpired();
    });

    AppState().sosTriggered.addListener(_onSosTriggered);
  }

  Future<void> _initScreenData() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt("userId");

    if (userId == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed("/login");
      return;
    }

    await _loadSuggestions();
    await _loadMessages();
    await _checkSelectedLocation();

    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_navigated) return;
      _loadMessages();
      _checkSelectedLocation();
      _checkMutualAcceptance();
    });
  }

  @override
  void dispose() {
    AppState().sosTriggered.removeListener(_onSosTriggered);
    _cleanUpTimers();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _cleanUpTimers() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _expireTimer?.cancel();
    _expireTimer = null;
  }

  void _onSosTriggered() async {
    if (!AppState().sosTriggered.value) return;
    if (_navigated || userId == null) return;
    
    setState(() {
      _navigated = true;
      _waitingForRecipient = false;
    });
    _cleanUpTimers();

    try {
      await ApiService.sendMessage(
        widget.matchId,
        userId!,
        "⚠️ Emergency SOS triggered. Meeting cancelled."
      );
      await ApiService.clearMeetLocation(widget.matchId);
    } catch (e) {
      debugPrint("Error saving SOS updates: $e");
    } finally {
      // CRITICAL FIX: Drops active match references completely to break home check loops
      AppState().clearActiveMatch(); 
      AppState().resetSos();
      AppState().isHandlingSosCleanup = false;
      AppState().justTriggeredSos = false;
    }

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil("/home", (route) => false);
  }

  Future<void> _goToMeetupMap(String name, String address, {double? lat, double? lon}) async {
    if (_navigated || userId == null) return;
    setState(() => _navigated = true);
    _cleanUpTimers();

    if (!_iAmChooser) {
      Future.delayed(const Duration(seconds: 5), () async {
        try {
          await ApiService.clearMeetLocation(widget.matchId);
        } catch (e) {
          debugPrint("clearMeetLocation error: $e");
        }
      });
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MeetupMapScreen(
          userId: userId!,
          otherUserId: widget.otherUserId,
          matchId: widget.matchId,
          placeName: name,
          placeAddress: address,
          placeLat: lat ?? _selectedPlaceLat,
          placeLon: lon ?? _selectedPlaceLon,
        ),
      ),
    );
  }

  void _handleSessionExpired() {
  if (_navigated) return;

  setState(() => _navigated = true);
  _cleanUpTimers();

  try {
    ApiService.clearMeetLocation(widget.matchId);
  } catch (_) {}

    if (!mounted) return;

    Navigator.of(context)
        .pushNamedAndRemoveUntil("/home", (route) => false);
  }

  Future<void> _loadSuggestions() async {
  if (userId == null) return;
  try {
    // Pass widget.matchId as the third argument here
    final res = await ApiService.getInterestSuggestions(userId!, widget.otherUserId, widget.matchId);
    if (!mounted || _navigated) return;
    setState(() {
      _suggestions = res;
      _loading = false;
    });
  } catch (e) {
    debugPrint("🔴 Error fetching suggestions: $e"); // Log the error to your console
    if (!mounted) return;
    setState(() => _loading = false);
  }
}

  Future<void> _loadMessages() async {
    if (_navigated) return;
    try {
      final msgs = await ApiService.getConversation(widget.matchId);
      if (!mounted || _navigated) return;
      setState(() => _messages = msgs);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && !_navigated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _checkSelectedLocation() async {
    if (_navigated || userId == null) return;

    try {
      final loc = await ApiService.getLocation(widget.matchId);
      debugPrint("LOCATION RESPONSE = $loc");
      if (_navigated) return;

      if (loc == null || loc["expired"] == true) {
        if (_locationEverExisted) _handleSessionExpired();
        return;
      }

      _locationEverExisted = true;
      _selectedPlaceLat ??= (loc["lat"] as num?)?.toDouble();
      _selectedPlaceLon ??= (loc["lon"] as num?)?.toDouble();

      final chooserId = (loc["chooserId"] as num?)?.toInt();
      final name = (loc["name"] ?? "Unknown place").toString();
      final address = (loc["address"] ?? "").toString();
      final acceptedByA = loc["acceptedByA"] == true;
      final acceptedByB = loc["acceptedByB"] == true;

      if (chooserId == null) return;

      final iAmChooser = chooserId == userId;
      final iAccepted = iAmChooser ? acceptedByA : acceptedByB;
      _iAmChooser = iAmChooser;

      if (!_initialCheckDone) {
        _initialCheckDone = true;
        if (iAmChooser && !iAccepted) {
          if (mounted) setState(() => _waitingForRecipient = true);
        }
        return;
      }

      if (iAccepted) {
        if (!iAmChooser && _waitingForRecipient) {
          if (mounted) setState(() => _waitingForRecipient = false);
        }
        return;
      }

      if (iAmChooser) {
        if (!_waitingForRecipient) {
          if (mounted) setState(() => _waitingForRecipient = true);
        }
        return;
      }

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
      debugPrint("MUTUAL RESPONSE = $res");
      if (_navigated) return;

      if (res["expired"] == true || res["sosTriggered"] == true) {
        _handleSessionExpired();
        return;
      }

      if (res["mutual"] == true) {
        final name = (res["name"] ?? "Meetup spot").toString();
        final address = (res["address"] ?? "").toString();
        final lat = (res["lat"] as num?)?.toDouble();
        final lon = (res["lon"] as num?)?.toDouble();
        if (mounted) await _goToMeetupMap(name, address, lat: lat, lon: lon);
      }
    } catch (e) {
      debugPrint("_checkMutualAcceptance error: $e");
    }
  }

  void _showIncomingLocationPopup(String name, String address) {
    if (_navigated || userId == null) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Meet at $name?"),
        content: Text(address.isNotEmpty ? address : "Your match chose a meetup spot."),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_navigated) return;
              try {
                await ApiService.acceptLocation(widget.matchId, userId!);
                if (mounted && !_navigated) setState(() => _waitingForRecipient = false);
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
    if (text.isEmpty || _navigated || userId == null) return;

    _msgController.clear();
    try {
      await ApiService.sendMessage(widget.matchId, userId!, text);
      await _loadMessages();
    } catch (_) {}
  }

  void _confirmLocationSelection(dynamic place) {
    if (_navigated || userId == null) return;
    final name = (place["name"] ?? "this place").toString();
    final address = (place["location"]?["formatted_address"] ?? "").toString();
    final fsqId = (place["fsq_place_id"] ?? "").toString();
    final lat = (place["latitude"] as num?)?.toDouble();
    final lon = (place["longitude"] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Choose $name?"),
        content: Text(address),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_navigated) return;
              try {
                await ApiService.selectMeetLocation(widget.matchId, userId!, fsqId, name, address, lat, lon);
                if (!mounted || _navigated) return;
                _iAmChooser = true;
                _locationEverExisted = true;
                _selectedPlaceLat = lat;
                _selectedPlaceLon = lon;
                setState(() => _waitingForRecipient = true);
              } catch (e) {
                if (mounted && !_navigated) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to select location: $e")));
                }
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

@override
  Widget build(BuildContext context) {
    if (_loading || userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final results = (_suggestions?["results"] is List) ? _suggestions["results"] as List : [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Suggested Places"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyScreen(userId: userId!)));
            },
          )
        ],
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                  ),
                  SizedBox(width: 10),
                  Text("Waiting for them to accept...", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            flex: 1,
            child: results.isEmpty
                ? const Center(child: Text("No suggestions found! :(", style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final place = results[index];
                      
                      // FIX: Safe check across potential camelCase/snake_case serialization variants
                      final fsqId = (place["fsq_place_id"] ?? place["fsqPlaceId"] ?? "").toString();
                      if (fsqId.isEmpty) {
                        debugPrint("⚠️ JSON Structure Warning: Skipped item missing ID fields: $place");
                        return const SizedBox.shrink();
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: ListTile(
                          title: Text(place["name"] ?? "Unknown Place", style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(place["location"]?["formatted_address"] ?? "Address unavailable"),
                          trailing: ElevatedButton(
                            onPressed: _waitingForRecipient ? null : () => _confirmLocationSelection(place),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.green.shade50,
                  child: const Text("Chat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = ((msg["senderId"] as num?)?.toInt() ?? -1) == userId;

                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(msg["content"] ?? "", style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgController,
                          decoration: InputDecoration(
                            hintText: "Suggest a meetup spot...",
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
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