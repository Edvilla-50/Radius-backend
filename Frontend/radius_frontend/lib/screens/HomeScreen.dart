import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MapScreen.dart';
import 'package:radius_frontend/screens/EmergencyScreen.dart';
import 'package:radius_frontend/screens/RankScreen.dart';
import 'package:radius_frontend/screens/ProfileScreen.dart';
import '../services/ApiService.dart';

class HomeScreen extends StatefulWidget {  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  int index = 0;
  int? userId;
  final Set<int> _shownRequestIds = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
  final prefs = await SharedPreferences.getInstance();
  setState(() {
    userId = prefs.getInt("userId") ?? 71; // ✅ default to Eddie for now
  });
  if (userId != null) {
    _startIncomingListener();
  }
}
  Future<void> _startIncomingListener() async {
  while (mounted) {
    await Future.delayed(const Duration(seconds: 3));
    try {
      final incoming = await ApiService.getIncoming(userId!);
      print('Incoming: $incoming'); 
      if (incoming.isNotEmpty) {
        final request = incoming[0];
        final id = request['id'] is String
        ? int.parse(request['id'])
        : request['id'] as int;

        if(!_shownRequestIds.contains(id)){
          _shownRequestIds.add(id);
          _showIncomingPopup(request);
        }
      }
    } catch (e) {
      print('Incoming error: $e'); 
      }
    }
  }
  void _showIncomingPopup(dynamic request) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Meet Request"),
        content: Text("User ${request['requesterId']} wants to meet!"),
        actions: [
          TextButton(
            onPressed: () {
              ApiService.respond(request['id'] is String
              ? int.parse(request['id'])
              : request['id'] as int, false);
              Navigator.pop(context);
            },
            child: const Text("Decline"),
          ),
          TextButton(
            onPressed: () {
              ApiService.respond(request['id'] is String
              ? int.parse(request['id'])
              : request['id'] as int, true);
              Navigator.pop(context);
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wait until userId is loaded
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [   
      MapScreen(userId: userId!),
      const Center(child: Text("Messages")),
      ProfileScreen(userId: userId!),
      RankScreen(userId: userId!),
      EmergencyScreen(userId: userId!),
    ];

    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) {
          setState(() => index = i);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(icon: Icon(Icons.interests), label: 'Trait Stack'),
          NavigationDestination(
            icon: Icon(Icons.emergency, color: Colors.red),
            selectedIcon: Icon(Icons.emergency, color: Colors.red),
            label: 'Emergency',
          ),
        ],
      ),
    );
  }
}
