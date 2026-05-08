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

  int _listenerGeneration = 0;

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
    final storedId = prefs.getInt("userId");

    if (storedId == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, "/login");
      return;
    }

    setState(() => userId = storedId);

    _shownRequestIds.clear();
    _startIncomingListener();
  }

  Future<void> _startIncomingListener() async {
    _stopListener = false;

    final myGeneration = ++_listenerGeneration;

    while (mounted && !_stopListener && _listenerGeneration == myGeneration) {
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted || _stopListener || _listenerGeneration != myGeneration) break;

      try {
        final incoming = await ApiService.getIncoming(userId!);

        if (!mounted || _stopListener || _listenerGeneration != myGeneration) break;

        if (incoming.isNotEmpty) {
          final req = incoming[0];
          final reqId = (req["id"] as num).toInt();

          if (!_shownRequestIds.contains(reqId) && !_isDialogShowing) {
            _shownRequestIds.add(reqId);
            _isDialogShowing = true;
            await _showIncomingPopup(req);
            _isDialogShowing = false;
          }
        }

        if (!mounted || _stopListener || _listenerGeneration != myGeneration) break;

        // Returns { "matchId": int, "otherUserId": int } or null
        final mutual = await ApiService.checkMutualForUser(userId!);

        if (!mounted || _stopListener || _listenerGeneration != myGeneration) break;

        if (mutual != null && !_isDialogShowing) {
          _stopListener = true;

          final matchId = (mutual["matchId"] as num).toInt();
          final otherUserId = (mutual["otherUserId"] as num).toInt();

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SuggestionsScreen(
                userId: userId!,
                otherUserId: otherUserId,
                matchId: matchId,
              ),
            ),
          ).then((_) {
            _startIncomingListener();
          });

          break;
        }
      } catch (e) {
        print("LISTENER ERROR: $e");
      }
    }
  }

  Future<void> _showIncomingPopup(dynamic req) async {
    final requesterId = (req["requesterId"] as num).toInt();
    final receiverId = (req["receiverId"] as num).toInt();
    final matchId = (req["matchId"] as num).toInt();
    final reqId = (req["id"] as num).toInt();

    final requester = await ApiService.getUser(requesterId);
    if (!mounted) return;

    final requesterName = requester["name"];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Meet Request"),
        content: Text("$requesterName wants to meet!"),
        actions: [
          TextButton(
            onPressed: () {
              ApiService.respond(reqId, false);
              Navigator.pop(context);
            },
            child: const Text("Decline"),
          ),
          TextButton(
            onPressed: () async {
              _stopListener = true;

              await ApiService.respond(reqId, true);
              if (!mounted) return;

              final otherUserId = requesterId == userId ? receiverId : requesterId;

              Navigator.pop(context);

              await Future.delayed(const Duration(milliseconds: 200));
              if (!mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SuggestionsScreen(
                    userId: userId!,
                    otherUserId: otherUserId,
                    matchId: matchId,
                  ),
                ),
              ).then((_) {
                _startIncomingListener();
              });
            },
            child: const Text("Accept"),
          ),
        ],
      ),
    );
  }

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