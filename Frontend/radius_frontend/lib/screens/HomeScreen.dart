import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ApiService.dart';
import '../state/AppState.dart';
import 'MapScreen.dart';
import 'RequestsScreen.dart';
import 'ProfileScreen.dart';
import 'RankScreen.dart';
import 'home_emergency_screen.dart';
import 'SuggestionsScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _stopListener = false;
  bool _isDialogShowing = false;
  bool _listenerRunning = false;
  int _listenerGeneration = 0;

  int index = 0;
  int? userId;
  final Set<int> _shownRequestIds = {};

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _stopListener = true;
    _listenerGeneration++;
    super.dispose();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final storedId = prefs.getInt('userId');

    if (storedId == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    setState(() => userId = storedId);
    _shownRequestIds.clear();
    _startIncomingListener();
  }

  Future<void> _startIncomingListener() async {
    if (_listenerRunning) {
      debugPrint('HOME: listener already running, skipping duplicate start');
      return;
    }
    _listenerRunning = true;
    _stopListener = false;
    final myGeneration = ++_listenerGeneration;

    while (mounted && !_stopListener && _listenerGeneration == myGeneration) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || _stopListener || _listenerGeneration != myGeneration) {
        break;
      }

      if (AppState().isHandlingSosCleanup || AppState().justTriggeredSos) {
        debugPrint(
          'HOME: SOS cleanup active. Skipping active match verification.',
        );
        continue;
      }

      try {
        final incoming = await ApiService.getIncoming(userId!);
        if (!mounted || _stopListener || _listenerGeneration != myGeneration) {
          break;
        }

        if (incoming.isNotEmpty) {
          final req = incoming[0];
          final reqId = (req['id'] as num).toInt();

          if (!_shownRequestIds.contains(reqId) && !_isDialogShowing) {
            _shownRequestIds.add(reqId);
            _isDialogShowing = true;
            try {
              await _showIncomingPopup(req);
            } finally {
              _isDialogShowing = false;
            }
          }
        }

        if (!mounted || _stopListener || _listenerGeneration != myGeneration) {
          break;
        }

        final mutual = await ApiService.checkMutualForUser(userId!);
        if (!mounted || _stopListener || _listenerGeneration != myGeneration) {
          break;
        }

        if (mutual != null &&
            !_isDialogShowing &&
            !AppState().isHandlingSosCleanup) {
          final matchId = (mutual['matchId'] as num).toInt();
          if (AppState().activeMatchId == matchId) continue;

          _stopListener = true;
          final otherUserId = (mutual['otherUserId'] as num).toInt();
          AppState().setActiveMatch(matchId);
          if (!mounted) break;

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  SuggestionsScreen(otherUserId: otherUserId, matchId: matchId),
            ),
            (route) => false,
          );
          break;
        }
      } catch (e) {
        debugPrint('LISTENER ERROR: $e');
      }
    }

    _listenerRunning = false;
  }

  Future<void> _showIncomingPopup(dynamic req) async {
    final requesterId = (req['requesterId'] as num).toInt();
    final receiverId = (req['receiverId'] as num).toInt();
    final matchId = (req['matchId'] as num).toInt();
    final reqId = (req['id'] as num).toInt();

    final requester = await ApiService.getUser(requesterId);
    if (!mounted || _stopListener) return;
    final requesterName = requester['name'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Meet Request'),
        content: Text('$requesterName wants to meet!'),
        actions: [
          TextButton(
            onPressed: () {
              ApiService.respond(reqId, false);
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Decline'),
          ),
          TextButton(
            onPressed: () async {
              _stopListener = true;
              try {
                await ApiService.respond(reqId, true);
              } catch (e) {
                debugPrint('Accept request error: $e');
                _stopListener = false;
                return;
              }
              if (!mounted) return;

              final otherUserId = requesterId == userId
                  ? receiverId
                  : requesterId;
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();

              await Future.delayed(const Duration(milliseconds: 200));
              if (!mounted) return;
              AppState().setActiveMatch(matchId);

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => SuggestionsScreen(
                    otherUserId: otherUserId,
                    matchId: matchId,
                  ),
                ),
                (route) => false,
              );
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      MapScreen(userId: userId!),
      RequestsScreen(userId: userId!),
      ProfileScreen(userId: userId!),
      RankScreen(userId: userId!),
      HomeEmergencyScreen(userId: userId!),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final verticalHinges = media.displayFeatures.where(
          (feature) =>
              feature.type == ui.DisplayFeatureType.hinge &&
              feature.bounds.height > feature.bounds.width,
        );

        // On a two-panel display, keep the rail in the first panel rather
        // than letting the active screen run underneath the hinge.
        double? leftPaneWidth;
        double? hingeWidth;
        for (final hinge in verticalHinges) {
          final localLeft = hinge.bounds.left - media.padding.left;
          if (localLeft > 0 && localLeft < constraints.maxWidth) {
            leftPaneWidth = localLeft;
            hingeWidth = hinge.bounds.width;
            break;
          }
        }

        final wide = constraints.maxWidth >= 700;
        final content = IndexedStack(index: index, children: pages);
        const destinations = [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.handshake), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
          NavigationDestination(
            icon: Icon(Icons.interests),
            label: 'Trait Stack',
          ),
          NavigationDestination(
            icon: Icon(Icons.emergency, color: Colors.red),
            label: 'Emergency',
          ),
        ];

        final rail = NavigationRail(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          labelType: NavigationRailLabelType.all,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.map),
              label: Text('Map'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.handshake),
              label: Text('Requests'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.person),
              label: Text('Profile'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.interests),
              label: Text('Traits'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.emergency, color: Colors.red),
              label: Text('Emergency'),
            ),
          ],
        );

        return Scaffold(
          body: wide
              ? SafeArea(
                  child: Row(
                    children: [
                      if (leftPaneWidth != null && hingeWidth != null) ...[
                        SizedBox(
                          width: leftPaneWidth,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: rail,
                          ),
                        ),
                        SizedBox(width: hingeWidth),
                      ] else ...[
                        rail,
                        const VerticalDivider(width: 1),
                      ],
                      Expanded(child: content),
                    ],
                  ),
                )
              : content,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => index = i),
                  destinations: destinations,
                ),
        );
      },
    );
  }
}
