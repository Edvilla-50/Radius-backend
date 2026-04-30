import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../services/ApiService.dart';
import 'package:latlong2/latlong.dart';
import '../services/LocationService.dart';
import 'ProfilePreviewScreen.dart';
import 'dart:async';
import 'SuggestionsScreen.dart';
//inherit StatefulWidget class
class MapScreen extends StatefulWidget{
  final int userId;//atrributes to make it unique
  const MapScreen ({super.key, required this.userId});//constuctir
  @override//first method to impliment
  State<MapScreen> createState()  => _MapScreenState();
}
//Map screen
class _MapScreenState extends State<MapScreen>{//impliment state class functions
  LatLng? _myLocation;//atrributes
  List<dynamic> _matches = [];
  bool _scanning = false;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _locationStream;
  @override//declare state
  void initState(){
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      await Geolocator.requestPermission();

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _myLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_myLocation!, 15.0);
      await ApiService.updateLocation(widget.userId, position.latitude, position.longitude);
      _locationStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) async{
        setState(() {
          _myLocation = LatLng(position.latitude, position.longitude);
        });
        await ApiService.updateLocation(widget.userId, position.latitude, position.longitude);
      });
    } catch(e){
      print('error: $e');
    }
  }

  Future<void> _sendRequest(int matchId) async{
    try{
      await ApiService.sendMeetRequest(widget.userId, matchId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request Sent')),
      );

      _waitForMutual(matchId);

    }catch(e){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending request'))
      );
    }
  }
  Future<void> _waitForMutual(int matchId) async{
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('waiting for mutual acceptance....')),
    );
    bool mutual = false;

    while(!mutual){
      await Future.delayed(const Duration(seconds: 3));

      mutual = await ApiService().checkMutual(widget.userId, matchId);
    }
      if(!mounted){
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestionsScreen(
            userId: widget.userId,
            matchId: matchId,
          ),
        ),
      );
  }
   Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final matches = await ApiService.getMatches(widget.userId);
      print('Matches recieved: $matches');
      setState(() {
        _matches = matches;
        _scanning = false;
      });
    } catch (e) {
      setState(() => _scanning = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _myLocation ?? LatLng(31.7619, -106.4850),
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
                      child: const Icon(Icons.person_pin_circle,
                        color: Colors.blue, size: 40),
                    ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
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
                  : const Text('SCAN', style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ),
          ),
          if (_matches.isNotEmpty)
            Positioned(
              top: 40,
              left: 10,
              right: 10,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListView.builder(
                  itemCount: _matches.length,
                  itemBuilder: (context, index) {
                    final match = _matches[index];
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
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfilePreviewScreen(
                              html: match['htmlProfile'] ??'<h1>${match['name']}</h1><p>No profile yet</p>',
                            ),
                          ),
                        );
                      },
                      trailing: ElevatedButton(
                        onPressed: () => _sendRequest(match['id'] as int),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreenAccent,
                          padding: const EdgeInsets.symmetric(horizontal:12,vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),)
                        ),
                        child: const Text(
                          "Request",
                          style: TextStyle(color: Colors.white),
                        )
                      )
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}