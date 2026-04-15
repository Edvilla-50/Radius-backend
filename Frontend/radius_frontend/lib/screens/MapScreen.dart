import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:latlong2/latlong.dart';
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

  @override//declare state
  void initState(){
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async{//getlocation from backend
    LocationPermission permission = await Geolocator.requestPermission();//request user permission to get location
    Position position = await Geolocator.getCurrentPosition();
    setState((){//call super variable Latlng
      _myLocation = LatLng(position.latitude, position.longitude);//call method to get location
      });
      await ApiService.updateLocation(widget.userId, position.latitude,position.longitude);//update widget based on api response
      _mapController.move(_myLocation!,15.0);//update map
  }

   Future<void> _scan() async {
    setState(() => _scanning = true);
    try {
      final matches = await ApiService.getMatches(widget.userId);
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
                  ..._matches.map((match) => Marker(
                    point: LatLng(match['lat'], match['lon']),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person_pin_circle,
                      color: Colors.red, size: 40),
                  )),
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
                      trailing: Text(
                        '${(match['score'] * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
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