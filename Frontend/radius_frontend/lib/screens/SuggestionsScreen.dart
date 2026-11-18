import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ApiService.dart';
import '../state/AppState.dart';
import 'EmergencyScreen.dart';
import 'MeetupMapScreen.dart';

class SuggestionsScreen extends StatefulWidget {
  final int otherUserId;
  final int matchId;
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
  bool _waitingForRecipient = false;
  bool _navigated = false;
  bool _popupShown = false;
  bool _iAmChooser = false;
  bool? _isSender;

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
    _expireTimer = Timer(const Duration(hours: 1), _handleSessionExpired);
    AppState().sosTriggered.addListener(_onSosTriggered);
  }

  Future<void> _initScreenData() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");

    if (!mounted) return;

    if (id == null) {
      Navigator.of(context).pushReplacementNamed("/login");
      return;
    }

    setState(() => userId = id);

    await _resolveRole();
    if (!mounted || _navigated) return;

    _loadMessages();
    _loadSuggestions();

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

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
    if (_navigated || userId == null || !mounted) return;

    setState(() {
      _navigated = true;
      _waitingForRecipient = false;
    });

    _cleanUpTimers();
    _closePopupIfOpen();

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

  Future<void> _goToMeetupMap(
    String name,
    String address, {
    double? lat,
    double? lon,
  }) async {
    if (_navigated || userId == null || !mounted) return;

    setState(() => _navigated = true);
    _cleanUpTimers();
    _closePopupIfOpen();

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

  Future<void> _handleSessionExpired() async {
    if (_navigated || !mounted) return;

    setState(() => _navigated = true);
    _cleanUpTimers();
    _closePopupIfOpen();

    try {
      await ApiService.clearMeetLocation(widget.matchId);
    } catch (e) {
      debugPrint("Clear location on expiry failed: $e");
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil("/home", (route) => false);
  }

  Future<void> _resolveRole() async {
    if (_isSender != null || userId == null) return;

    try {
      final res = await ApiService.getMeetRole(
        widget.matchId,
        userId!,
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      final sender = res["isSender"] == true;

      setState(() {
        _isSender = sender;
        _iAmChooser = sender;
      });
    } catch (e) {
      debugPrint("Role lookup failed: $e");
    }
  }

  Future<void> _loadSuggestions() async {
    if (userId == null || _navigated) return;

    if (mounted) {
      setState(() {
        _loadingSuggestions = true;
        _suggestionsError = null;
      });
    }

    try {
      final res = await ApiService.getInterestSuggestions(
        userId!,
        widget.otherUserId,
        widget.matchId,
      ).timeout(const Duration(seconds: 45));

      if (!mounted || _navigated) return;

      setState(() {
        _suggestions = res;
        _loadingSuggestions = false;
      });
    } catch (e) {
      if (!mounted || _navigated) return;

      final err = e.toString();
      String message;

      if (err.contains("Backend error 409")) {
        message =
            "We need both of your locations to find a spot between you. "
            "Make sure you've both checked in (tap SCAN), then try again.";
      } else if (err.contains("TimeoutException")) {
        message = "This is taking longer than usual. Try again.";
      } else {
        message =
            "Couldn't load suggested places. Check your connection and try again.";
      }

      setState(() {
        _loadingSuggestions = false;
        _suggestionsError = message;
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
        if (!mounted || _navigated) return;
        if (!_scrollController.hasClients) return;

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      debugPrint("Message loading error: $e");
    }
  }

  Future<void> _checkSelectedLocation() async {
    if (_navigated || userId == null) return;

    try {
      final loc = await ApiService.getLocation(widget.matchId);

      if (!mounted || _navigated) return;

      if (loc != null && loc["expired"] == true) {
        _handleSessionExpired();
        return;
      }

      if (loc != null) {
        _applyServerExpiry(loc["expiresAt"]);
      }

      if (loc == null || loc["hasSelection"] != true) {
        if (_locationEverExisted) {
          final wasWaiting = _waitingForRecipient;

          _locationEverExisted = false;
          _popupShown = false;
          _selectedPlaceLat = null;
          _selectedPlaceLon = null;

          _closePopupIfOpen();

          if (mounted) {
            setState(() => _waitingForRecipient = false);
          }

          if (wasWaiting) {
            _showSnack("They'd like a different spot. Pick another one!");
          }
        }
        return;
      }

      _locationEverExisted = true;
      _applyServerExpiry(loc["expiresAt"]);

      _selectedPlaceLat = (loc["lat"] as num?)?.toDouble();
      _selectedPlaceLon = (loc["lon"] as num?)?.toDouble();

      final chooserId = (loc["chooserId"] as num?)?.toInt();
      final name = (loc["name"] ?? "Unknown place").toString();
      final address = (loc["address"] ?? "").toString();
      final locationId = (loc["locationId"] ?? "").toString();
      final acceptedByB = loc["acceptedByB"] == true;

      if (chooserId == null && _isSender == null) return;

      final iAmChooser = chooserId != null
          ? chooserId == userId
          : (_isSender ?? false);

      _iAmChooser = iAmChooser;

      if (_isSender != iAmChooser && mounted) {
        setState(() => _isSender = iAmChooser);
      }

      if (iAmChooser) {
        final waiting = !acceptedByB;

        if (mounted && _waitingForRecipient != waiting) {
          setState(() => _waitingForRecipient = waiting);
        }
        return;
      }

      if (acceptedByB) return;

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
      debugPrint("Location check error: $e");
    }
  }

  Future<void> _checkMutualAcceptance() async {
    if (_navigated) return;

    try {
      final res = await ApiService.checkMutual(widget.matchId);

      if (!mounted || _navigated) return;

      if (res["expired"] == true || res["sosTriggered"] == true) {
        _handleSessionExpired();
        return;
      }

      if (res["mutual"] == true) {
        final name = (res["name"] ?? "Meetup spot").toString();
        final address = (res["address"] ?? "").toString();
        final lat = (res["lat"] as num?)?.toDouble();
        final lon = (res["lon"] as num?)?.toDouble();

        await _goToMeetupMap(name, address, lat: lat, lon: lon);
      }
    } catch (e) {
      debugPrint("Mutual acceptance check error: $e");
    }
  }

  void _showIncomingLocationPopup(
    String name,
    String address,
    String locationId,
  ) {
    if (_navigated || userId == null || !mounted) return;

    _popupPlaceKey = "$locationId|$name|$address";

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _popupContext = dialogCtx;

        return AlertDialog(
          title: Text("Meet at $name?"),
          content: Text(
            address.isNotEmpty ? address : "Your match chose a meetup spot.",
          ),
          actions: [
            TextButton(
              onPressed: () async {
                _popupContext = null;
                _popupPlaceKey = null;
                Navigator.pop(dialogCtx);

                if (_navigated) return;

                try {
                  await ApiService.resetMeetLocation(widget.matchId, userId!);

                  await ApiService.sendMessage(
                    widget.matchId,
                    userId!,
                    "Could we pick a different spot?",
                  );

                  if (!mounted || _navigated) return;

                  _locationEverExisted = false;
                  _selectedPlaceLat = null;
                  _selectedPlaceLon = null;
                  _popupShown = false;
                  _loadMessages();
                } catch (e) {
                  debugPrint("Decline location error: $e");
                  _popupShown = false;
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

                  if (mounted && !_navigated) {
                    setState(() => _waitingForRecipient = false);
                  }
                } catch (e) {
                  debugPrint("Accept location error: $e");
                  _popupShown = false;
                  _showSnack("Couldn't confirm. Try again.");
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

  Future<void> _changePlace() async {
    if (_navigated || userId == null) return;

    try {
      await ApiService.resetMeetLocation(widget.matchId, userId!);

      if (!mounted || _navigated) return;

      _locationEverExisted = false;
      _selectedPlaceLat = null;
      _selectedPlaceLon = null;

      setState(() => _waitingForRecipient = false);
    } catch (e) {
      debugPrint("Change place error: $e");
      _showSnack("Couldn't change the place. Try again.");
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();

    if (text.isEmpty || _navigated || userId == null) {
      return;
    }

    _msgController.clear();

    try {
      await ApiService.sendMessage(widget.matchId, userId!, text);
      await _loadMessages();
    } catch (e) {
      debugPrint("Send message error: $e");
      if (!mounted || _navigated) return;
      _msgController.text = text;
      _showSnack("Couldn't send message. Try again.");
    }
  }

  void _confirmLocationSelection(dynamic place) {
    if (_navigated || userId == null || !mounted) return;

    final name = (place["name"] ?? "this place").toString();
    final address = (place["location"]?["formatted_address"] ?? "").toString();
    final fsqId = (place["fsq_place_id"] ?? place["fsqPlaceId"] ?? "")
        .toString();
    final lat = (place["latitude"] as num?)?.toDouble();
    final lon = (place["longitude"] as num?)?.toDouble();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text("Choose $name?"),
        content: Text(address),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (_navigated) return;

              try {
                await ApiService.selectMeetLocation(
                  widget.matchId,
                  userId!,
                  fsqId,
                  name,
                  address,
                  lat,
                  lon,
                );

                if (!mounted || _navigated) return;

                _iAmChooser = true;
                _locationEverExisted = true;
                _selectedPlaceLat = lat;
                _selectedPlaceLon = lon;

                setState(() => _waitingForRecipient = true);
              } catch (e) {
                _showSnack(
                  "Only the sender can suggest a place. "
                  "Please wait and chat with them.",
                );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_suggestionsError!, textAlign: TextAlign.center),
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
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("No suggestions found! :("),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadSuggestions,
              child: const Text("Try again"),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final place = results[index];

        final fsqId = (place["fsq_place_id"] ?? place["fsqPlaceId"] ?? "")
            .toString();

        if (fsqId.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            title: Text(
              (place["name"] ?? "Unknown Place").toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              (place["location"]?["formatted_address"] ?? "Address unavailable")
                  .toString(),
            ),
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

  Widget _buildChatMessages(ThemeData theme, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isMe = ((msg["senderId"] as num?)?.toInt() ?? -1) == userId;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.green
                  : isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              (msg["content"] ?? "").toString(),
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatComposer(ThemeData theme, bool isDark) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: theme.colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _msgController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: "Suggest a meetup spot...",
                  filled: true,
                  fillColor: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: "Send message",
              icon: const Icon(Icons.send, color: Colors.green),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final results = _suggestions?["results"] is List
        ? _suggestions["results"] as List
        : <dynamic>[];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Suggested Places"),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            tooltip: "Emergency SOS",
            icon: const Icon(Icons.sos, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmergencyScreen(userId: userId!),
                ),
              );
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;

          final suggestionsPane = _buildSuggestionsArea(results);

          final chatPane = Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: isDark
                    ? theme.colorScheme.surfaceContainerHighest
                    : Colors.green.shade50,
                child: const Text(
                  "Chat",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              Expanded(child: _buildChatMessages(theme, isDark)),
              _buildChatComposer(theme, isDark),
            ],
          );

          return Column(
            children: [
              if (_waitingForRecipient)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: isDark
                      ? Colors.green.shade900.withValues(alpha: 0.4)
                      : Colors.green.shade100,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const Text("Waiting for them to accept..."),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.green.shade50,
                  child: const Text(
                    "They're choosing a meetup spot. "
                    "Chat below, and you'll be asked "
                    "to confirm once they pick one.",
                    textAlign: TextAlign.center,
                  ),
                ),
              Expanded(
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: suggestionsPane),
                          const VerticalDivider(width: 1),
                          Expanded(child: chatPane),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: suggestionsPane),
                          const Divider(height: 1),
                          Expanded(child: chatPane),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
