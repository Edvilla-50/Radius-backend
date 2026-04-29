import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MapScreen.dart';
import 'package:radius_frontend/screens/EmergencyScreen.dart';
import 'package:radius_frontend/screens/RankScreen.dart';
import 'package:radius_frontend/screens/ProfileScreen.dart';

class HomeScreen extends StatefulWidget {  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  int index = 0;
  int? userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt("userId");
    });
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
