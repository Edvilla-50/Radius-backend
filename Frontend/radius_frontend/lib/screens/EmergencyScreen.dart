import 'package:flutter/material.dart';
import 'package:radius_frontend/enums/EmergencyType.dart';
import 'package:radius_frontend/services/ApiService.dart';
import 'package:radius_frontend/services/LocationService.dart';
import 'package:radius_frontend/state/AppState.dart';

class EmergencyScreen extends StatefulWidget {
  final int userId;
  const EmergencyScreen({super.key, required this.userId});
  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  EmergencyType? selectedType;
  bool isSending = false;
  String note = "";

  Future<void> sendAlert() async {
    if (selectedType == null) return;
    setState(() => isSending = true);
    try {
      final position = await LocationService.getCurrentLocation();
      await ApiService.sendEmergency(
        userId: widget.userId,
        type: selectedType!,
        lat: position.latitude,
        lon: position.longitude,
        note: note,
      );

      // Notify the screen underneath (SuggestionsScreen / MeetupMapScreen) that
      // an SOS was triggered. That screen owns the matchId and is responsible
      // for sending the cancellation message, clearing the meet location, and
      // navigating home itself via its own sosTriggered listener.
      //
      // IMPORTANT: We do NOT navigate home from here. Doing so previously raced
      // against the underlying screen's cleanup — popping/clearing the navigator
      // stack could dispose that screen (and remove its sosTriggered listener)
      // before its _onSosTriggered handler ran, so the cancellation message and
      // clearMeetLocation call were sometimes skipped entirely.
      AppState().triggerSos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency alert sent")),
      );

      // Simply pop back to the screen that pushed us (SuggestionsScreen or
      // MeetupMapScreen). That screen's sosTriggered listener will have already
      // fired (or will fire momentarily) and will handle its own cleanup and
      // navigation to "/home".
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send alert")),
      );
    }
    if (mounted) setState(() => isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Emergency Assistance")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Select your situation:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RadioListTile<EmergencyType>(
              title: const Text("I feel unsafe"),
              value: EmergencyType.unsafe,
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
            ),
            RadioListTile<EmergencyType>(
              title: const Text("I am hurt"),
              value: EmergencyType.injured,
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
            ),
            RadioListTile<EmergencyType>(
              title: const Text("I need to be picked up"),
              value: EmergencyType.pickup,
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: "Optional note",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => note = value,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isSending ? null : sendAlert,
              child: isSending
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Send Alert"),
            ),
          ],
        ),
      ),
    );
  }
}