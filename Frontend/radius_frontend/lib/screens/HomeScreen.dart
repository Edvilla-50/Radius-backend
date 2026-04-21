import 'package:flutter/material.dart';
import 'MapScreen.dart';
import 'package:radius_frontend/screens/EmergencyScreen.dart';




class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;

  final pages = [
    MapScreen(userId: 71),
    Center(child: Text("Messages")),
    Center(child: Text("Profile")),
    EmergencyScreen(userId: 71),
  ];

  @override
  Widget build(BuildContext context) {
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
          NavigationDestination(icon: Icon(Icons.emergency,color: Colors.red), selectedIcon: Icon(Icons.emergency, color: Colors.red), label:'Emergency'),
        ],
      ),
    );
  }
}