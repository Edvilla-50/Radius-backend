import 'package:flutter/material.dart';
import 'package:radius_frontend/enums/EmergencyType.dart';
import 'package:radius_frontend/services/ApiService.dart';
import 'package:radius_frontend/services/LocationService.dart';
import 'package:radius_frontend/state/AppState.dart';

class HomeEmergencyScreen extends StatefulWidget {
  final int userId;
  const HomeEmergencyScreen({super.key, required this.userId});

  @override
  State<HomeEmergencyScreen> createState() => _HomeEmergencyScreenState();
}

class _HomeEmergencyScreenState extends State<HomeEmergencyScreen> {
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

      AppState().triggerSos();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency alert sent")),
      );

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
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