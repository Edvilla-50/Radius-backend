import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'package:latlong2/latlong.dart';
//inherit StatefulWidget class
class MapScreen extends StatefulWidget{
  final int userId;//atrributes to make it unique
  const MapScreen ({super.key, required this.userId})//constuctir

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
}