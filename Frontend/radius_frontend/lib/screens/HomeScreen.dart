import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ApiService.dart';
import 'MapScreen.dart';
import 'MessagesScreen.dart';
import 'ProfileScreen.dart';
import 'RankScreen.dart';
import 'EmergencyScreen.dart';
import 'SuggestionsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _stopListener = false;
  bool _isDialogShowing = false;

  int index = 0;
  int? userId;

  final Set<int> _shownRequestIds = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  // ---------------------------------------------------------
  // LOAD USER
  // ---------------------------------------------------------
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getInt("userId");

    if (storedId == null) {
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    setState(() => userId = storedId);

    _startIncomingListener();
  }

  // ---------------------------------------------------------
  // INCOMING REQUEST LISTENER
  // ---------------------------------------------------------
  Future<void> _startIncomingListener() async {
    while (mounted && !_stopListener) {
      await Future.delayed(const Duration(seconds: 3));
      if (_stopListener) return;

      try {
        // 1. Check incoming meet requests
        final incoming = await ApiService.getIncoming(userId!);
        if (_stopListener) return;

        if (incoming.isNotEmpty) {
          final request = incoming[0];

          final requestId = request['id'] is String
              ? int.parse(request['id'])
              : request['id'] as int;

          if (!_shownRequestIds.contains(requestId) && !_isDialogShowing) {
            _shownRequestIds.add(requestId);

            _isDialogShowing = true;
            await _showIncomingPopup(request);
            _isDialogShowing = false;
          }
        }

        if (_stopListener) return;

        // 2. Check mutual match
        final mutualMatchId = await ApiService.checkMutualForUser(userId!);
        if (_stopListener) return;

        if (mutualMatchId != null && !_isDialogShowing) {
          print("Mutual match detected → navigating");

          _stopListener = true;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuggestionsScreen(
                userId: userId!,
                otherUserId: mutualMatchId,
                matchId: mutualMatchId, // TEMP until backend returns real matchId
              ),
            ),
          );

          return;
        }
      } catch (e) {
        print("Incoming listener error: $e");
      }
    }
  }

  // ---------------------------------------------------------
  // POPUP FOR INCOMING REQUEST
  // ---------------------------------------------------------
  Future<void> _showIncomingPopup(dynamic request) async {
    final requesterId = request['requesterId'];
    final requester = await ApiService.getUser(requesterId);
    final requesterName = requester['name'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Meet Request"),
        content: Text("$requesterName wants to meet!"),
        actions: [
          // DECLINE
          TextButton(
            onPressed: () {
              ApiService.respond(
                request['id'] is String
                    ? int.parse(request['id'])
                    : request['id'] as int,
                false,
              );
              if (Navigator.canPop(context)) Navigator.pop(context);
            },
            child: const Text("Decline"),
          ),

          // ACCEPT
          TextButton(
            onPressed: () async {
              try {
                print("Accept pressed");
                _stopListener = true;

                final requestId = request['id'] is String
                    ? int.parse(request['id'])
                    : request['id'] as int;

                await ApiService.respond(requestId, true);
                print("ACCEPT SENT");

                final requesterId = request['requesterId'];
                final receiverId = request['receiverId'];

                final otherUserId =
                    requesterId == userId ? receiverId : requesterId;

                final matchId = request['matchId'];

                if (Navigator.canPop(context)) Navigator.pop(context);

                await Future.delayed(const Duration(milliseconds: 200));

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SuggestionsScreen(
                      userId: userId!,
                      otherUserId: otherUserId,
                      matchId: matchId,
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

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      MapScreen(userId: userId!),
      MessagesScreen(userId: userId!),
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
        onDestinationSelected: (i) => setState(() => index = i),
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
