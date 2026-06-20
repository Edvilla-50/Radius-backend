import 'package:flutter/foundation.dart';

class AppState {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  final ValueNotifier<bool> sosTriggered = ValueNotifier(false);
  bool justTriggeredSos = false;
  bool isHandlingSosCleanup = false;
  int? activeMatchId;

  void triggerSos() {
    if (sosTriggered.value) return; // Prevent double execution triggers
    justTriggeredSos = true;
    isHandlingSosCleanup = true;
    sosTriggered.value = true;
  }

  void resetSos() {
    justTriggeredSos = false;
    isHandlingSosCleanup = false;
    sosTriggered.value = false;
  }

  void setActiveMatch(int matchId) {
    activeMatchId = matchId;
  }

  void clearActiveMatch() {
    activeMatchId = null;
  }
}