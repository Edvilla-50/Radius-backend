import 'package:flutter/material.dart';
import 'MapScreen.dart';
import 'package:radius_frontend/screens/EmergencyScreen.dart';
import 'package:radius_frontend/screens/RankScreen.dart';

class HomeScreen extends StatefulWidget {  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [   // ✅ moved inside build
      MapScreen(userId: 71),
      Center(child: Text("Messages")),
      Center(child: Text("Profile")),
      RankScreen(userId: 71),
      EmergencyScreen(userId: 71),
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
          NavigationDestination(icon: Icon(Icons.emergency, color: Colors.red), selectedIcon: Icon(Icons.emergency, color: Colors.red), label: 'Emergency'),
        ],
      ),
    );
  }
}