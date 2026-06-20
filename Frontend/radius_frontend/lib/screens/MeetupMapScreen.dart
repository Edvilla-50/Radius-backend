import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ApiService.dart';
import '../state/AppState.dart';
import '../screens/EmergencyScreen.dart';
import 'dart:async';

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

  LatLng? _myLocation;
  LatLng? _otherLocation;
  LatLng? _placeLocation;

  Timer? _pollTimer;
  StreamSubscription? _locationStream;
  Timer? _expireTimer;

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

    _expireTimer = Timer(const Duration(hours: 1), () {
      _exitToHomeUnconditionally();
    });

    AppState().sosTriggered.addListener(_onSosTriggered);
  }

  @override
  void dispose() {
    AppState().sosTriggered.removeListener(_onSosTriggered);
    _cleanUpResources();
    super.dispose();
  }

  void _cleanUpResources() {
    _pollTimer?.cancel();
    _locationStream?.cancel();
    _expireTimer?.cancel();
  }

  void _exitToHomeUnconditionally() {
    if (_navigated) return;

    setState(() => _navigated = true);
    _cleanUpResources();

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      "/home",
      (route) => false,
    );
  }

  void _onSosTriggered() async {
    if (!AppState().sosTriggered.value) return;
    if (_navigated) return;

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
    }

    AppState().resetSos();
    AppState().isHandlingSosCleanup = false;
    AppState().justTriggeredSos = false;

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      "/home",
      (route) => false,
    );
  }

  Future<void> _init() async {
    try {
      if (_placeLocation == null) {
        await _geocodePlaceFromMidpoint();
      }

      await _startMyLocation();
      await _fetchOtherLocation();

      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (_navigated) return;

        await _fetchOtherLocation();

        try {
          final res = await ApiService.checkMutual(widget.matchId);
          
          // Fallback: If a user clears the meeting room entirely, the result could be null
          if (res == null) {
            debugPrint("⚠️ Match record missing from server. Routing home.");
            _exitToHomeUnconditionally();
            return;
          }

          _pollCount++;
          if (_pollCount < 3) return;

          // Extract values tied to your updated MeetRequest Java properties
          final bool isSosTriggered = res["sosTriggered"] == true;
          final bool isExpired = res["expired"] == true;

          debugPrint("📊 POLLED STATUS -> isSosTriggered: $isSosTriggered | isExpired: $isExpired");

          // Active background exit validation loop for both connected clients
          if (isSosTriggered || isExpired) {
            debugPrint("⚠️ Match constraint invalidated (SOS/Expired). Cleaning up and exiting.");
            _exitToHomeUnconditionally();
          }
        } catch (e) {
          debugPrint("poll error: $e");
          // Handle network dropouts or database 404/500 errors safely by routing home
          _exitToHomeUnconditionally();
        }
      });
    } catch (e) {
      debugPrint("_init error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _navigated) return;

      if (_placeLocation != null) {
        _mapController.move(_placeLocation!, 15.0);
      } else if (_myLocation != null) {
        _mapController.move(_myLocation!, 15.0);
      }
    });
  }

  Future<void> _geocodePlaceFromMidpoint() async {
    try {
      final midpoint = await ApiService.getMidpoint(
        widget.userId,
        widget.otherUserId,
      );

      final lat = (midpoint["lat"] as num?)?.toDouble();
      final lon = (midpoint["lon"] as num?)?.toDouble();

      if (lat != null && lon != null) {
        _placeLocation = LatLng(lat, lon);
      }
    } catch (e) {
      debugPrint("_geocodePlaceFromMidpoint error: $e");
    }
  }

  Future<void> _startMyLocation() async {
    try {
      await Geolocator.requestPermission();

      final position = await Geolocator
          .getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      if (mounted && !_navigated) {
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
      }

      await ApiService.updateLocation(
        widget.userId,
        position.latitude,
        position.longitude,
      );

      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) async {
        if (_navigated) return;

        if (mounted) {
          setState(() {
            _myLocation = LatLng(pos.latitude, pos.longitude);
          });
        }

        await ApiService.updateLocation(
          widget.userId,
          pos.latitude,
          pos.longitude,
        );
      });
    } catch (e) {
      debugPrint("_startMyLocation error: $e");
    }
  }

  Future<void> _fetchOtherLocation() async {
    try {
      final user = await ApiService.getUser(widget.otherUserId);

      final lat = (user["lat"] as num?)?.toDouble();
      final lon = (user["lon"] as num?)?.toDouble();

      if (lat != null && lon != null && mounted && !_navigated) {
        setState(() {
          _otherLocation = LatLng(lat, lon);
        });
      }
    } catch (e) {
      debugPrint("_fetchOtherLocation error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.placeName),
            Text(
              widget.placeAddress,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmergencyScreen(userId: widget.userId),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        _placeLocation ?? _myLocation ?? const LatLng(0, 0),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.radius.app',
                    ),
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
                        if (_otherLocation != null)
                          Marker(
                            point: _otherLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.person_pin_circle,
                              color: Colors.orange,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                Positioned(
                  bottom: 30,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "sos",
                    backgroundColor: Colors.red,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EmergencyScreen(userId: widget.userId),
                        ),
                      );
                    },
                    child: const Icon(Icons.sos),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: "recenter",
                    backgroundColor: Colors.green,
                    onPressed: () {
                      if (_placeLocation != null) {
                        _mapController.move(_placeLocation!, 15.0);
                      } else if (_myLocation != null) {
                        _mapController.move(_myLocation!, 15.0);
                      }
                    },
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
    );
  }
}