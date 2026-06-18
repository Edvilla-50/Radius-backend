import 'package:flutter/foundation.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<bool> sosTriggered = ValueNotifier(false);
  bool justTriggeredSos = false;

  // Persistent lock to stop HomeScreen polling during background network operations
  bool isHandlingSosCleanup = false;

  // Tracks the matchId of the meetup currently in progress (set when the user
  // enters SuggestionsScreen/MeetupMapScreen), so other parts of the app can
  // reference the active match without needing it passed through context.
  int? activeMatchId;

  void triggerSos() {
    justTriggeredSos = true;
    isHandlingSosCleanup = true;
    sosTriggered.value = true;
  }

  void resetSos() {
    sosTriggered.value = false;
  }

  void setActiveMatch(int? matchId) {
    activeMatchId = matchId;
  }
}