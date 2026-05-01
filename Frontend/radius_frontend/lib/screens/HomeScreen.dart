import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'MapScreen.dart';
import 'package:radius_frontend/screens/EmergencyScreen.dart';
import 'package:radius_frontend/screens/RankScreen.dart';
import 'package:radius_frontend/screens/ProfileScreen.dart';
import '../services/ApiService.dart';
import 'package:radius_frontend/screens/SuggestionsScreen.dart';

class HomeScreen extends StatefulWidget {  
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  bool _stopListener = false;
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
    userId = prefs.getInt("userId") ?? 71; 
  });
  if (userId != null) {
    _startIncomingListener();
  }
}
bool _isDialogShowing = false;
Future<void> _startIncomingListener() async {
  while (mounted && !_stopListener) {
    await Future.delayed(const Duration(seconds: 3));
    if(_stopListener){
      return;
    }
    try {
      // -------------------------------
      // ⭐ 1. CHECK INCOMING REQUESTS (recipient flow FIRST)
      // -------------------------------
      final incoming = await ApiService.getIncoming(userId!);
      if(_stopListener){
        return;
      }
      print('Incoming: $incoming');

      if (incoming.isNotEmpty) {
        final request = incoming[0];
        final id = request['id'] is String
            ? int.parse(request['id'])
            : request['id'] as int;

        if (!_shownRequestIds.contains(id) && !_isDialogShowing) {
          _shownRequestIds.add(id);

          _isDialogShowing = true;
          await _showIncomingPopup(request);
          _isDialogShowing = false;
        }
      }
      if(_stopListener){
        return;
      }
      // -------------------------------
      // ⭐ 2. CHECK MUTUAL ACCEPTANCE (sender flow SECOND)
      // -------------------------------
      final mutualOtherUser = await ApiService.checkMutualForUser(userId!);
      print("MUTUAL CHECK RESULT: $mutualOtherUser"); // 👈
      print("_isDialogShowing: $_isDialogShowing");   // 👈
      print("_stopListener: $_stopListener");  
      if(_stopListener){
        return;
      }
      if (mutualOtherUser != null && !_isDialogShowing && !_stopListener) {
        print("Mutual detected for sender! Navigating...");

        _stopListener = true;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SuggestionsScreen(
              userId: userId!,
              otherUserId: mutualOtherUser,
            ),
          ),
        );

        return;
      }

    } catch (e) {
      print('Incoming error: $e');
    }
  }
}

Future<void> _showIncomingPopup(dynamic request) async {
  final requesterId = request['requesterId'];
  final requester = await ApiService.getUser(requesterId);
  final requesterName = requester['name'];

  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Meet Request"),
      content: Text("$requesterName wants to meet!"),
      actions: [
        TextButton(
          onPressed: () {
            ApiService.respond(
              request['id'] is String
                  ? int.parse(request['id'])
                  : request['id'] as int,
              false,
            );
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

          },
          child: const Text("Decline"),
        ),
      TextButton(
  onPressed: () async {
    print('accept pushed!');

    try {
      _stopListener = true;

      final requestId = request['id'] is String
          ? int.parse(request['id'])
          : request['id'] as int;

      // Send acceptance
      await ApiService.respond(requestId, true);
      print("ACCEPT SENT");

      final requesterId = request['requesterId'];
      final receiverId = request['receiverId'];

      // Determine the other user
      final otherUserId =
          requesterId == userId ? receiverId : requesterId;

      // Close popup FIRST (important)
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Small delay to avoid navigation issues
      await Future.delayed(const Duration(milliseconds: 200));

      // Navigate immediately (DO NOT wait for mutual)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestionsScreen(
            userId: userId!,
            otherUserId: otherUserId,
          ),
        ),
      );

    } catch (e) {
      print("ACCEPT ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error accepting request")),
      );
    }
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
