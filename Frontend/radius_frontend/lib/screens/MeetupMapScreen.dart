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
    _pollTimer = null;
    _locationStream?.cancel();
    _locationStream = null;
    _expireTimer?.cancel();
    _expireTimer = null;
  }

  void _exitToHomeUnconditionally() {
    if (_navigated) return;
    setState(() => _navigated = true);
    _cleanUpResources();

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil("/home", (route) => false);
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
        "⚠️ Emergency SOS triggered. Meeting cancelled."
      );
      await ApiService.clearMeetLocation(widget.matchId);
    } catch (e) {
      debugPrint("SOS map state clear failure: $e");
    } finally {
      // Locks only release after the asynchronous backend calls have completed
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
      await _startMyLocation();
      await _fetchOtherLocation();

      _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (_navigated) return;
        await _fetchOtherLocation();

        try {
          final res = await ApiService.checkMutual(widget.matchId);
          if (res != null && (res["expired"] == true || res["sosTriggered"] == true)) {
            _exitToHomeUnconditionally();
          }
        } catch (_) {}
      });
    } catch (e) {
      debugPrint("MeetupMapScreen _init error: $e");
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
      final midpoint = await ApiService.getMidpoint(widget.userId, widget.otherUserId);
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
      final position = await Geolocator.getCurrentPosition().timeout(const Duration(seconds: 10));

      if (mounted && !_navigated) {
        setState(() => _myLocation = LatLng(position.latitude, position.longitude));
      }

      await ApiService.updateLocation(widget.userId, position.latitude, position.longitude);

      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      ).listen((pos) async {
        if (_navigated) return;
        if (mounted) {
          setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        }
        await ApiService.updateLocation(widget.userId, pos.latitude, pos.longitude);
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
        setState(() => _otherLocation = LatLng(lat, lon));
      }
    } catch (e) {
      debugPrint("_fetchOtherLocation error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.placeName),
            Text(widget.placeAddress, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.sos, color: Colors.white),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyScreen(userId: widget.userId)));
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
                    initialCenter: _placeLocation ?? _myLocation ?? const LatLng(0, 0),
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.radius.app',
                    ),
                    MarkerLayer(
                      markers: [
                        if (_placeLocation != null)
                          Marker(
                            point: _placeLocation!,
                            width: 60,
                            height: 60,
                            child: Column(
                              children: const [
                                Icon(Icons.location_pin, color: Colors.red, size: 40),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    "Meet here",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_myLocation != null)
                          Marker(
                            point: _myLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                          ),
                        if (_otherLocation != null)
                          Marker(
                            point: _otherLocation!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.person_pin_circle, color: Colors.orange, size: 40),
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyScreen(userId: widget.userId)));
                    },
                    child: const Icon(Icons.sos, color: Colors.white),
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
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),
    );
  }
}