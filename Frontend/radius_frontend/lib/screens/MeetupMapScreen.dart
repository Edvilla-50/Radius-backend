import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/ApiService.dart';
import '../state/AppState.dart';
import 'EmergencyScreen.dart';
import 'ProfilePreviewScreen.dart';
import 'radius_tile_layer.dart';

class MeetupMapScreen extends StatefulWidget {
  final int userId;
  final int otherUserId;
  final int matchId;
  final String placeName;
  final String placeAddress;
  final double? placeLat;
  final double? placeLon;

  const MeetupMapScreen({
    super.key,
    required this.userId,
    required this.otherUserId,
    required this.matchId,
    required this.placeName,
    required this.placeAddress,
    this.placeLat,
    this.placeLon,
  });

  @override
  State<MeetupMapScreen> createState() => _MeetupMapScreenState();
}

class _MeetupMapScreenState extends State<MeetupMapScreen> {
  final MapController _mapController = MapController();

  // The user's location is displayed locally only.
  // This screen never fetches or displays the other
  // participant's live location.
  LatLng? _myLocation;
  LatLng? _placeLocation;

  Timer? _pollTimer;
  Timer? _expireTimer;
  StreamSubscription<Position>? _locationStream;

  bool _loading = true;
  bool _navigated = false;
  int _pollCount = 0;

  @override
  void initState() {
    super.initState();

    if (widget.placeLat != null && widget.placeLon != null) {
      _placeLocation = LatLng(widget.placeLat!, widget.placeLon!);
    }

    _init();

    _expireTimer = Timer(const Duration(hours: 1), _exitToHomeUnconditionally);

    AppState().sosTriggered.addListener(_onSosTriggered);
  }

  @override
  void dispose() {
    AppState().sosTriggered.removeListener(_onSosTriggered);

    _cleanUpResources();
    _mapController.dispose();
    super.dispose();
  }

  void _cleanUpResources() {
    _pollTimer?.cancel();
    _pollTimer = null;

    _locationStream?.cancel();
    _locationStream = null;

    _expireTimer?.cancel();
    _expireTimer = null;
  }

  void _exitToHomeUnconditionally() {
    if (_navigated || !mounted) return;

    setState(() => _navigated = true);
    _cleanUpResources();

    Navigator.of(context).pushNamedAndRemoveUntil("/home", (route) => false);
  }

  void _onSosTriggered() async {
    if (!AppState().sosTriggered.value) return;
    if (_navigated || !mounted) return;

    setState(() => _navigated = true);
    _cleanUpResources();

    try {
      await ApiService.sendMessage(
        widget.matchId,
        widget.userId,
        "⚠️ Emergency SOS triggered. Meeting cancelled.",
      );

      await ApiService.clearMeetLocation(widget.matchId);
    } catch (e) {
      debugPrint("SOS error: $e");
    } finally {
      AppState().clearActiveMatch();
      AppState().resetSos();
      AppState().isHandlingSosCleanup = false;
      AppState().justTriggeredSos = false;
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil("/home", (route) => false);
  }

  Future<void> _init() async {
    try {
      if (_placeLocation == null) {
        await _geocodePlaceFromMidpoint();
      }

      if (!mounted || _navigated) return;

      await _startMyLocation();

      if (!mounted || _navigated) return;

      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (_navigated || !mounted) return;

        try {
          final res = await ApiService.checkMutual(widget.matchId);

          if (!mounted || _navigated) return;

          _pollCount++;

          if (_pollCount < 3) return;

          final isSosTriggered = res["sosTriggered"] == true;
          final isExpired = res["expired"] == true;

          if (isSosTriggered || isExpired) {
            _exitToHomeUnconditionally();
          }
        } catch (e) {
          debugPrint("Meetup polling error: $e");

          if (mounted && !_navigated) {
            _exitToHomeUnconditionally();
          }
        }
      });
    } catch (e) {
      debugPrint("Meetup map initialization error: $e");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;

      final target = _placeLocation ?? _myLocation;

      if (target != null) {
        _mapController.move(target, 15.0);
      }
    });
  }

  Future<void> _geocodePlaceFromMidpoint() async {
    try {
      final midpoint = await ApiService.getMidpoint(
        widget.userId,
        widget.otherUserId,
      );

      if (!mounted || _navigated) return;

      final lat = (midpoint["lat"] as num?)?.toDouble();
      final lon = (midpoint["lon"] as num?)?.toDouble();

      if (lat != null && lon != null) {
        _placeLocation = LatLng(lat, lon);
      }
    } catch (e) {
      debugPrint("Midpoint lookup error: $e");
    }
  }

  Future<void> _startMyLocation() async {
    try {
      await Geolocator.requestPermission();

      if (!mounted || _navigated) return;

      final position = await Geolocator.getCurrentPosition().timeout(
        const Duration(seconds: 10),
      );

      if (!mounted || _navigated) return;

      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });

      _locationStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            ),
          ).listen(
            (pos) {
              if (_navigated || !mounted) return;

              setState(() {
                _myLocation = LatLng(pos.latitude, pos.longitude);
              });
            },
            onError: (Object error) {
              debugPrint("Location stream error: $error");
            },
          );
    } catch (e) {
      debugPrint("Location access error: $e");
    }
  }

  void _recenterMap() {
    final target = _placeLocation ?? _myLocation;

    if (target != null) {
      _mapController.move(target, 15.0);
    }
  }

  void _openParticipantProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfilePreviewScreen(userId: widget.otherUserId.toString()),
      ),
    );
  }

  void _openEmergencyScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EmergencyScreen(userId: widget.userId)),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _placeLocation ?? _myLocation ?? const LatLng(0, 0),
            initialZoom: 15.0,
          ),
          children: [
            radiusTileLayer(context),

            MarkerLayer(
              markers: [
                if (_placeLocation != null)
                  Marker(
                    point: _placeLocation!,
                    width: 60,
                    height: 60,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
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

            radiusAttribution(),
          ],
        ),

        Positioned(
          bottom: 30,
          left: 16,
          child: FloatingActionButton(
            heroTag: "meetup_sos",
            backgroundColor: Colors.red,
            onPressed: _openEmergencyScreen,
            child: const Icon(Icons.sos),
          ),
        ),

        Positioned(
          bottom: 30,
          right: 16,
          child: FloatingActionButton(
            heroTag: "meetup_recenter",
            backgroundColor: Colors.green,
            onPressed: _recenterMap,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsPanel() {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.place, color: Colors.green, size: 48),
          const SizedBox(height: 12),

          Text(
            widget.placeName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Text(widget.placeAddress, textAlign: TextAlign.center),

          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: _recenterMap,
            icon: const Icon(Icons.my_location),
            label: const Text("Recenter map"),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _openParticipantProfile,
            icon: const Icon(Icons.person),
            label: const Text("View participant"),
          ),

          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: _openEmergencyScreen,
            icon: const Icon(Icons.sos, color: Colors.red),
            label: const Text("Emergency assistance"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.placeName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.placeAddress,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            tooltip: "View participant",
            onPressed: _openParticipantProfile,
          ),
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white),
            tooltip: "Emergency SOS",
            onPressed: _openEmergencyScreen,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;

                if (!wide) {
                  return _buildMap();
                }

                final panelWidth = (constraints.maxWidth * 0.32).clamp(
                  280.0,
                  400.0,
                );

                return Row(
                  children: [
                    Expanded(child: _buildMap()),
                    const VerticalDivider(width: 1),
                    SizedBox(width: panelWidth, child: _buildDetailsPanel()),
                  ],
                );
              },
            ),
    );
  }
}
