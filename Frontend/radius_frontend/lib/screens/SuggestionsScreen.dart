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

  // true  = this user sent the meetup request (picks the place)
  // false = this user received the request (waits, chats, then accepts)
  // null  = unknown; fall back to the server's chooserId, as before.
  final bool? isSender;

  const SuggestionsScreen({
    super.key,
    required this.otherUserId,
    required this.matchId,
    this.isSender,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  bool _loadingSuggestions = true;
  String? _suggestionsError;
  dynamic _suggestions;
  List<dynamic> _messages = [];

  int? userId;

  bool _initialCheckDone = false;
  bool _waitingForRecipient = false;
  bool _navigated = false;
  bool _popupShown = false;
  bool _iAmChooser = false;
  bool? _isSender;

  // Currently open "Meet at X?" dialog (recipient side), so it can be closed
  // if the sender changes or clears the place while it is showing.
  BuildContext? _popupContext;
  String? _popupPlaceKey;

  double? _selectedPlaceLat;
  double? _selectedPlaceLon;
  bool _locationEverExisted = false;

  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollTimer;
  Timer? _expireTimer;
  DateTime? _serverExpiresAt;

  @override
  void initState() {
    super.initState();
    _isSender = widget.isSender;
    _iAmChooser = widget.isSender ?? false;
    _initScreenData();

    // Fallback only. Once the server sends expiresAt, _applyServerExpiry()
    // replaces this so reopening the screen can't extend the session.
    _expireTimer = Timer(const Duration(hours: 1), _handleSessionExpired);

    AppState().sosTriggered.addListener(_onSosTriggered);
  }

  Future<void> _initScreenData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");

    if (id == null) {
      if (mounted) Navigator.of(context).pushReplacementNamed("/login");
      return;
    }

    if (!mounted) return;
    setState(() => userId = id);

    await _resolveRole();
    if (!mounted) return;

    _loadMessages();

    await _loadSuggestions();
    if (!mounted || _navigated) return;

    await _checkSelectedLocation();
    if (!mounted || _navigated) return;

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

  // Uses the server's expiry time when it provides one.
  void _applyServerExpiry(dynamic raw) {
    if (raw == null) return;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null || parsed == _serverExpiresAt) return;
    _serverExpiresAt = parsed;
    _expireTimer?.cancel();
    final remaining = parsed.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _handleSessionExpired();
    } else {
      _expireTimer = Timer(remaining, _handleSessionExpired);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _closePopupIfOpen() {
    final ctx = _popupContext;
    _popupContext = null;
    _popupPlaceKey = null;
    if (ctx != null && ctx.mounted) {
      Navigator.of(ctx).pop();
    }
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
        "⚠️ Emergency SOS triggered. Meeting cancelled.",
      );
      await ApiService.clearMeetLocation(widget.matchId);
    } catch (e) {
      debugPrint("Error saving SOS updates: $e");
    } finally {
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

  // FIX: async + awaited, so a failed clearMeetLocation is actually caught,
  // and setState is guarded by `mounted`.
  Future<void> _handleSessionExpired() async {
    if (_navigated || !mounted) return;

    setState(() => _navigated = true);
    _cleanUpTimers();
    _closePopupIfOpen();

    try {
      await ApiService.clearMeetLocation(widget.matchId);
    } catch (e) {
      debugPrint("clearMeetLocation on expiry failed: $e");
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil("/home", (route) => false);
  }

  Future<void> _resolveRole() async {
    if (_isSender != null || userId == null) return;
    try {
      final res = await ApiService.getMeetRole(widget.matchId, userId!)
          .timeout(const Duration(seconds: 20));
      final sender = res["isSender"] == true;
      if (!mounted) return;
      setState(() {
        _isSender = sender;
        _iAmChooser = sender;
      });
    } catch (e) {
      debugPrint("Role lookup failed, falling back to server chooser: $e");
    }
  }

  Future<void> _loadSuggestions() async {
    if (userId == null) return;
    if (mounted) {
      setState(() {
        _loadingSuggestions = true;
        _suggestionsError = null;
      });
    }
    try {
      final res = await ApiService
          .getInterestSuggestions(userId!, widget.otherUserId, widget.matchId)
          .timeout(const Duration(seconds: 45));
      if (!mounted || _navigated) return;
      setState(() {
        _suggestions = res;
        _loadingSuggestions = false;
      });
    } catch (e) {
      debugPrint("🔴 Error fetching suggestions: $e");
      if (!mounted) return;
      setState(() {
        _loadingSuggestions = false;
        _suggestionsError =
            "Couldn't load suggested places. Check your connection and try again.";
      });
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

      if (loc != null && loc["expired"] == true) {
        _handleSessionExpired();
        return;
      }

      if (loc != null) _applyServerExpiry(loc["expiresAt"]);

      // No place selected (null, or the server's hasSelection:false). This means
      // "cleared / reset", not "expired": expiry and SOS arrive as expired:true
      // here or via _checkMutualAcceptance (expired / sosTriggered flags).
      if (loc == null || loc["hasSelection"] != true) {
        if (_locationEverExisted) {
          final wasWaiting = _waitingForRecipient;
          _locationEverExisted = false;
          _popupShown = false;
          _selectedPlaceLat = null;
          _selectedPlaceLon = null;
          _closePopupIfOpen();
          if (mounted) setState(() => _waitingForRecipient = false);
          if (wasWaiting) {
            _showSnack("They'd like a different spot. Pick another one!");
          }
        }
        return;
      }

      _locationEverExisted = true;
      _applyServerExpiry(loc["expiresAt"]);

      // FIX: assign directly so a changed place doesn't keep stale coordinates.
      _selectedPlaceLat = (loc["lat"] as num?)?.toDouble();
      _selectedPlaceLon = (loc["lon"] as num?)?.toDouble();

      final chooserId = (loc["chooserId"] as num?)?.toInt();
      final name = (loc["name"] ?? "Unknown place").toString();
      final address = (loc["address"] ?? "").toString();
      final locationId = (loc["locationId"] ?? "").toString();
      final acceptedByA = loc["acceptedByA"] == true;
      final acceptedByB = loc["acceptedByB"] == true;

      if (chooserId == null && _isSender == null) return;

      final iAmChooser = _isSender ?? (chooserId == userId);
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

      // Recipient side. If the sender swapped the place while the dialog is
      // open, close the stale one and show the new one.
      final placeKey = "$locationId|$name|$address";
      if (_popupContext != null && _popupPlaceKey != placeKey) {
        _closePopupIfOpen();
        _popupShown = false;
      }

      if (!_popupShown) {
        _popupShown = true;
        _showIncomingLocationPopup(name, address, locationId);
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

  // FIX: recipient can now decline ("Pick another") instead of being forced
  // to accept.
  void _showIncomingLocationPopup(String name, String address, String locationId) {
    if (_navigated || userId == null) return;
    _popupPlaceKey = "$locationId|$name|$address";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _popupContext = dialogCtx;
        return AlertDialog(
          title: Text("Meet at $name?"),
          content: Text(address.isNotEmpty ? address : "Your match chose a meetup spot."),
          actions: [
            TextButton(
              onPressed: () async {
                _popupContext = null;
                _popupPlaceKey = null;
                Navigator.pop(dialogCtx);
                if (_navigated) return;
                try {
                  // _popupShown stays true until the reset lands, so a poll
                  // in between can't reopen the same dialog.
                  await ApiService.resetMeetLocation(widget.matchId, userId!);
                  await ApiService.sendMessage(
                    widget.matchId,
                    userId!,
                    "Could we pick a different spot?",
                  );
                  _locationEverExisted = false;
                  _selectedPlaceLat = null;
                  _selectedPlaceLon = null;
                  _popupShown = false;
                  _loadMessages();
                } catch (e) {
                  debugPrint("resetMeetLocation (decline) error: $e");
                  _popupShown = false; // let the poll show it again
                  _showSnack("Couldn't decline right now. Try again.");
                }
              },
              child: const Text("Pick another"),
            ),
            TextButton(
              onPressed: () async {
                _popupContext = null;
                _popupPlaceKey = null;
                Navigator.pop(dialogCtx);
                if (_navigated) return;
                try {
                  await ApiService.acceptLocation(
                    widget.matchId,
                    userId!,
                    locationId: locationId.isEmpty ? null : locationId,
                  );
                  if (mounted && !_navigated) setState(() => _waitingForRecipient = false);
                } catch (e) {
                  debugPrint("acceptLocation error: $e");
                  _showSnack("Couldn't confirm. Try again.");
                  _popupShown = false;
                }
              },
              child: const Text("Let's go!"),
            ),
          ],
        );
      },
    ).then((_) {
      _popupContext = null;
      _popupPlaceKey = null;
    });
  }

  // FIX: sender can take back their pick while waiting.
  Future<void> _changePlace() async {
    if (_navigated || userId == null) return;
    try {
      await ApiService.resetMeetLocation(widget.matchId, userId!);
      _locationEverExisted = false;
      _selectedPlaceLat = null;
      _selectedPlaceLon = null;
      if (mounted) setState(() => _waitingForRecipient = false);
    } catch (e) {
      debugPrint("resetMeetLocation (change) error: $e");
      _showSnack("Couldn't change the place. Try again.");
    }
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
    final fsqId = (place["fsq_place_id"] ?? place["fsqPlaceId"] ?? "").toString();
    final lat = (place["latitude"] as num?)?.toDouble();
    final lon = (place["longitude"] as num?)?.toDouble();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text("Choose $name?"),
        content: Text(address),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
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
                _showSnack("Failed to select location: $e");
              }
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsArea(List results) {
    if (_loadingSuggestions) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Finding places for you..."),
          ],
        ),
      );
    }

    if (_suggestionsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _suggestionsError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadSuggestions,
                child: const Text("Try again"),
              ),
            ],
          ),
        ),
      );
    }

    if (results.isEmpty) {
      return const Center(child: Text("No suggestions found! :(", style: TextStyle(fontSize: 18)));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final place = results[index];

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
            trailing: _iAmChooser
                ? ElevatedButton(
                    onPressed: _waitingForRecipient
                        ? null
                        : () => _confirmLocationSelection(place),
                    child: const Text("Select"),
                  )
                : null,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.green.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
                  ),
                  const SizedBox(width: 10),
                  const Text("Waiting for them to accept...",
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  // FIX: sender can change their mind.
                  TextButton(
                    onPressed: _changePlace,
                    child: const Text("Change place"),
                  ),
                ],
              ),
            ),
          if (_isSender == false && !_navigated)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.green.shade50,
              child: const Text(
                "They're choosing a meetup spot. Chat below, and you'll be asked to confirm once they pick one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black87, fontSize: 14),
              ),
            ),
          Expanded(
            flex: 1,
            child: _buildSuggestionsArea(results),
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
                          style: const TextStyle(color: Colors.black87),
                          cursorColor: Colors.black87,
                          decoration: InputDecoration(
                            hintText: "Suggest a meetup spot...",
                            hintStyle: const TextStyle(color: Colors.black45),
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