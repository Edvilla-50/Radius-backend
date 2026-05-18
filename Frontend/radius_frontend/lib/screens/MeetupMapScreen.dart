import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ApiService.dart';
import 'dart:async';

class MeetupMapScreen extends StatefulWidget {
  final int userId;
  final int otherUserId;
  final String placeName;
  final String placeAddress;

  const MeetupMapScreen({
    super.key,
    required this.userId,
    required this.otherUserId,
    required this.placeName,
    required this.placeAddress,
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

  bool _loading = true;

  @override
  void initState() {
    super.initState();
      print("DEBUG: MeetupMapScreen initState");
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _locationStream?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      await _geocodePlace();
      await _startMyLocation();
      await _fetchOtherLocation();

      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _fetchOtherLocation();
      });
    } catch (e) {
      debugPrint("MeetupMapScreen _init error: $e");
    } finally {
      // Always stop loading regardless of errors
      print("DEBUG: _init finally, mounted=$mounted, loading will be false");
      if (mounted) setState(() => _loading = false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_placeLocation != null) {
        _mapController.move(_placeLocation!, 15.0);
      } else if (_myLocation != null) {
        _mapController.move(_myLocation!, 15.0);
      }
    });
  }

  Future<void> _geocodePlace() async {
    try {
      final midpoint = await ApiService.getMidpoint(
              widget.userId, widget.otherUserId)
          .timeout(const Duration(seconds: 10));
      final lat = (midpoint["lat"] as num?)?.toDouble();
      final lon = (midpoint["lon"] as num?)?.toDouble();
      if (lat != null && lon != null) {
        _placeLocation = LatLng(lat, lon);
      }
    } catch (e) {
      debugPrint("_geocodePlace error: $e");
    }
  }

  Future<void> _startMyLocation() async {
    try {
      await Geolocator.requestPermission();

      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 10));

      if (mounted) {
        setState(() => _myLocation = LatLng(position.latitude, position.longitude));
      }

      await ApiService.updateLocation(
          widget.userId, position.latitude, position.longitude);

      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((pos) async {
        if (mounted) {
          setState(() => _myLocation = LatLng(pos.latitude, pos.longitude));
        }
        await ApiService.updateLocation(
            widget.userId, pos.latitude, pos.longitude);
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
      if (lat != null && lon != null && mounted) {
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
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 50,
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
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendItem(color: Colors.red, label: "Meet here"),
                        SizedBox(height: 6),
                        _LegendItem(color: Colors.blue, label: "You"),
                        SizedBox(height: 6),
                        _LegendItem(color: Colors.orange, label: "Them"),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 30,
                  right: 16,
                  child: FloatingActionButton(
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, color: color, size: 12),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}