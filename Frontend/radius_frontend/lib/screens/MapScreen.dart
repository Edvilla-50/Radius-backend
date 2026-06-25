import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../services/ApiService.dart';
import '../services/LocationService.dart';
import 'ProfilePreviewScreen.dart';
import 'SuggestionsScreen.dart';
import 'OnboardingScreen.dart';

const String _spotifyPlaylistUrl = 'https://open.spotify.com/playlist/4mmKm7hFzxAn2XYtx4JqRS?si=6A0E9NdDSjaBp7pExHlXIw&pi=YsDnlnQNQAePF';
const String _appleMusicPlaylistUrl = 'https://music.apple.com/us/playlist/the-radius-soundtrack/pl.u-jV899DNFDe543bD';

class MapScreen extends StatefulWidget {
  final int userId;
  const MapScreen({super.key, required this.userId});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  LatLng? _myLocation;
  List<dynamic> _matches = [];
  bool _scanning = false;
  bool _ghostMode = false;
  bool _ghostModeLoading = false;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationStream;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _loadGhostMode();
  }

  @override
  void dispose() {
    _locationStream?.cancel();
    _locationStream = null;
    super.dispose();
  }

  Future<void> _loadGhostMode() async {
    try {
      final user = await ApiService.getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _ghostMode = user["ghostMode"] == true;
      });
    } catch (e) {
      debugPrint('MapScreen _loadGhostMode error: $e');
    }
  }

  Future<void> _toggleGhostMode() async {
    final newValue = !_ghostMode;
    setState(() => _ghostModeLoading = true);
    try {
      await ApiService.updateGhostMode(widget.userId, newValue);
      if (!mounted) return;
      setState(() {
        _ghostMode = newValue;
        _ghostModeLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newValue ? 'Ghost mode on — you\'re hidden' : 'Ghost mode off'),
        ),
      );
      if (newValue) {
        _scan();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _ghostModeLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update ghost mode')),
      );
    }
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
        if (!mounted) return;
        _mapController.move(_myLocation!, 15.0);
      });
      await ApiService.updateLocation(
          widget.userId, position.latitude, position.longitude);
      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async {
        if (!mounted) return;
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
        await ApiService.updateLocation(
            widget.userId, position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('MapScreen _getLocation error: $e');
    }
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
    setState(() => _scanning = true);
    try {
      final matches = await ApiService.getMatches(widget.userId);
      if (!mounted) return;
      setState(() {
        _matches = matches;
        _scanning = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _scanning = false);
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
    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? const LatLng(31.7619, -106.4850),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.radius.app',
              ),
              MarkerLayer(
                markers: [
                  if (_myLocation != null)
                    Marker(
                      point: _myLocation!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Ghost Mode Button
          Positioned(
            top: 45,
            right: 70,
            child: FloatingActionButton.small(
              heroTag: "ghost_mode_btn",
              backgroundColor: _ghostMode
                  ? Colors.deepPurple
                  : Colors.white.withOpacity(0.9),
              onPressed: _ghostModeLoading ? null : _toggleGhostMode,
              child: _ghostModeLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _ghostMode
                          ? Icons.visibility_off
                          : Icons.visibility_off_outlined,
                      color: _ghostMode ? Colors.white : Colors.blue,
                    ),
            ),
          ),

          // Tutorial Button
          Positioned(
            top: 45,
            right: 15,
            child: FloatingActionButton.small(
              heroTag: "tutorial_btn",
              backgroundColor: Colors.white.withOpacity(0.9),
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
            bottom: 40,
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
          if (_matches.isNotEmpty)
            Positioned(
              top: 105,
              left: 10,
              right: 10,
              child: SizedBox(
                height: 150,
                child: Material(
                  elevation: 2,
                  color: Colors.white.withOpacity(0.9),
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
                        title: Text(match['name']),
                        subtitle: Text(
                          '${(match['score'] * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        onTap: () async {
                          final blocked = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePreviewScreen(
                                userId: matchId.toString(),
                              ),
                            ),
                          );
                          if (blocked == true && mounted) {
                            setState(() {
                              _matches.removeWhere(
                                (m) => (m['id'] as num).toInt() == matchId,
                              );
                            });
                          }
                        },
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
    );
  }
}