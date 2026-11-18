import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../services/ApiService.dart';
import 'ProfilePreviewScreen.dart';
import 'OnboardingScreen.dart';
import 'radius_tile_layer.dart'; // Make sure this path matches your project structure
import 'dart:ui' as ui;

const String _spotifyPlaylistUrl = 'https://open.spotify.com/playlist/4mmKm7hFzxAn2XYtx4JqRS?si=6A0E9NdDSjaBp7pExHlXIw&pi=YsDnlnQNQAePF';
const String _appleMusicPlaylistUrl = 'https://music.apple.com/us/playlist/the-radius-soundtrack/pl.u-jV899DNFDe543bD';

class MapScreen extends StatefulWidget {
  final int userId;
  const MapScreen({super.key, required this.userId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  LatLng? _myLocation;
  List<dynamic> _matches = [];
  bool _scanning = false;
  bool _checkedIn = false;
  int? _selectedProfileId;
  Timer? _expiryTimer;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationStream;

  static const Duration _checkInDuration = Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getLocation();
    _checkOut();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiryTimer?.cancel();
    _locationStream?.cancel();
    _locationStream = null;
    ApiService.checkOut(widget.userId).catchError((e) {
      debugPrint('MapScreen dispose hide error: $e');
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _checkOut();
    }
  }

  Future<void> _checkOut() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    try {
      await ApiService.checkOut(widget.userId);
    } catch (e) {
      debugPrint('MapScreen _checkOut error: $e');
    }
    if (!mounted) return;
    setState(() {
      _checkedIn = false;
      _matches = [];
      _selectedProfileId = null;
    });
  }

  Future<void> _getLocation() async {
    try {
      await Geolocator.requestPermission();
      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _myLocation == null) return;
        _mapController.move(_myLocation!, 15.0);
      });
      await _locationStream?.cancel();
      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (!mounted) return;
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
      });
    } catch (e) {
      debugPrint('MapScreen _getLocation error: $e');
    }
  }

  void _recenterMap() {
    if (_myLocation == null) {
      _getLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );
      return;
    }
    _mapController.move(_myLocation!, 15.0);
  }

  Future<void> _openProfile(int userId, bool wide) async {
    if (wide) {
      setState(() => _selectedProfileId = userId);
      return;
    }
    final blocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePreviewScreen(userId: userId.toString()),
      ),
    );
    if (blocked == true && mounted) _removeBlockedUser(userId);
  }

  void _removeBlockedUser(int userId) {
    setState(() {
      _matches.removeWhere((m) => (m['id'] as num).toInt() == userId);
      if (_selectedProfileId == userId) _selectedProfileId = null;
    });
  }

  Future<void> _sendRequest(int otherUserId) async {
    try {
      await ApiService.sendMeetRequest(widget.userId, otherUserId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request Sent')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending request')),
      );
    }
  }

  Future<void> _scan() async {
    if (!mounted) return;

    if (!_checkedIn) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Check in?'),
          content: const Text(
            'Your location will be visible to nearby Radius users for '
            '30 minutes, or until you tap Stop Sharing or close the app.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Check in'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() => _scanning = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      _myLocation = LatLng(position.latitude, position.longitude);

      await ApiService.checkIn(
        widget.userId,
        position.latitude,
        position.longitude,
      );
      final matches = await ApiService.getMatches(widget.userId);

      _expiryTimer?.cancel();
      _expiryTimer = Timer(_checkInDuration, _checkOut);

      if (!mounted) return;
      setState(() {
        _matches = matches;
        if (_selectedProfileId != null &&
            !matches.any((m) => (m['id'] as num).toInt() == _selectedProfileId)) {
          _selectedProfileId = null;
        }
        _checkedIn = true;
        _scanning = false;
      });
    } catch (e) {
      debugPrint('MapScreen _scan error: $e');
      if (!mounted) return;
      setState(() => _scanning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check in. Please try again.')),
      );
    }
  }

  void _showPlaylistEasterEgg() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎧 You found it!'),
        content: const Text(
          'Here\'s the official Radius playlist — good music for good vibes while you scan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(_spotifyPlaylistUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Spotify'),
          ),
          TextButton(
            onPressed: () async {
              final uri = Uri.parse(_appleMusicPlaylistUrl);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            },
            child: const Text('Apple Music'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final verticalHinges = media.displayFeatures.where((feature) =>
        feature.type == ui.DisplayFeatureType.hinge &&
        feature.bounds.height > feature.bounds.width).toList();
        final hinge = verticalHinges.isEmpty ? null : verticalHinges.first;
        // Keep a single-column layout when the usable regions are too narrow.
        final wide = constraints.maxWidth >= 720 &&
            (hinge == null ||
                (hinge.bounds.left >= 360 &&
                 constraints.maxWidth - hinge.bounds.right >= 280));
        final panelWidth = hinge != null && wide
            ? constraints.maxWidth - hinge.bounds.right
            : (constraints.maxWidth >= 1050 ? 340.0 : 280.0);
        final hingeGap = hinge != null && wide ? hinge.bounds.width : 0.0;
        final safeTop = MediaQuery.paddingOf(context).top;
        final safeBottom = MediaQuery.paddingOf(context).bottom;
        return Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
          // Map Layer with dynamic dark mode filter & attribution
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? const LatLng(31.7619, -106.4850),
              initialZoom: 15.0,
            ),
            children: [
              radiusTileLayer(context),
              MarkerLayer(
                markers: [
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.person_pin_circle,
                        color: _checkedIn ? Colors.blue : Colors.grey,
                        size: 40,
                      ),
                    ),
                ],
              ),
              radiusAttribution(),
            ],
          ),

          // Status banner
          Positioned(
            top: safeTop + 16,
            left: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _checkedIn ? Icons.location_on : Icons.location_off,
                    size: 16,
                    color: _checkedIn ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _checkedIn ? 'Checked in' : 'Hidden',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stop Sharing Button
          if (_checkedIn)
            Positioned(
              top: safeTop + 16,
              right: 70,
              child: FloatingActionButton.small(
                heroTag: "stop_sharing_btn",
                backgroundColor: Colors.deepPurple,
                tooltip: 'Stop sharing',
                onPressed: _checkOut,
                child: const Icon(Icons.location_off, color: Colors.white),
              ),
            ),

          // Recenter Map Button
          Positioned(
            right: 15,
            bottom: safeBottom + 100,
            child: FloatingActionButton.small(
              heroTag: "recenter_map_btn",
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              onPressed: _recenterMap,
              child: const Icon(
                Icons.my_location,
                color: Colors.blue,
              ),
            ),
          ),

          // Tutorial Button
          Positioned(
            top: safeTop + 16,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "tutorial_btn",
              backgroundColor: Colors.white.withValues(alpha: 0.9),
              child: const Icon(Icons.help_outline, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const OnboardingScreen(isTutorial: true),
                  ),
                );
              },
            ),
          ),

          // Scan Button
          Positioned(
            bottom: safeBottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onLongPress: _showPlaylistEasterEgg,
                child: ElevatedButton(
                  onPressed: _scanning ? null : _scan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _scanning
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'SCAN',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),

          // Matches Container
          if (!wide && _matches.isNotEmpty)
            Positioned(
              top: 105,
              left: 10,
              right: 10,
              child: SizedBox(
                height: 150,
                child: Material(
                  elevation: 2,
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _matches.length,
                    itemBuilder: (context, index) {
                      final match = _matches[index];
                      final matchId = (match['id'] as num).toInt();
                      return ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: Text(
                          match['name']?.toString() ?? 'Unknown user',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${(match['score'] * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                         onTap: () => _openProfile(matchId, false),
trailing: ElevatedButton(
                          onPressed: () => _sendRequest(matchId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightGreenAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            "Request",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
                  ],
                ),
              ),
              if (wide) ...[
                if (hingeGap > 0) SizedBox(width: hingeGap),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: panelWidth - 1,
                  child: _selectedProfileId != null
                      ? Column(
                          children: [
                            SafeArea(
                              bottom: false,
                              child: ListTile(
                                leading: IconButton(
                                  tooltip: 'Back to nearby users',
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => setState(
                                    () => _selectedProfileId = null,
                                  ),
                                ),
                                title: const Text('Nearby users'),
                              ),
                            ),
                            Expanded(
                              child: ProfilePreviewScreen(
                                key: ValueKey(_selectedProfileId),
                                userId: _selectedProfileId.toString(),
                                embedded: true,
                                onBlocked: () => _removeBlockedUser(
                                  _selectedProfileId!,
                                ),
                              ),
                            ),
                          ],
                        )
                      : SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                                child: Text(
                                  'Nearby users',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(_checkedIn
                                    ? 'Visible for up to 30 minutes'
                                    : 'You are hidden until you check in.'),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _matches.isEmpty
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text(
                                            'No nearby matches yet. Tap SCAN on the map to check in.',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: _matches.length,
                                        itemBuilder: (context, index) {
                                          final match = _matches[index];
                                          final matchId =
                                              (match['id'] as num).toInt();
                                          return ListTile(
                                            leading: const Icon(Icons.person,
                                                color: Colors.blue),
                                            title: Text(match['name']?.toString() ??
                                                'Unknown user'),
                                            subtitle: Text(
                                              '${(match['score'] * 100).toStringAsFixed(0)}% match',
                                            ),
                                            onTap: () => _openProfile(matchId, true),
                                            trailing: IconButton(
                                              icon: const Icon(Icons.person_add_alt_1),
                                              tooltip: 'Send meetup request',
                                              onPressed: () => _sendRequest(matchId),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}