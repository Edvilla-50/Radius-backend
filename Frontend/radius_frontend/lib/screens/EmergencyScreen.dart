import 'package:flutter/material.dart';
import 'package:radius_frontend/enums/EmergencyType.dart';
import 'package:radius_frontend/services/ApiService.dart';
import 'package:radius_frontend/services/LocationService.dart';

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
      double lat = position.latitude;
      double lon = position.longitude;

      await ApiService.sendEmergency(
        userId: widget.userId,
        type: selectedType!,
        lat: position.latitude,
        lon: position.longitude,
        note: note,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emergency alert sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send alert")),
      );
    }

    setState(() => isSending = false);
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

            RadioListTile(
              title: const Text("I feel unsafe"),
              value: EmergencyType.unsafe,
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
            ),

            RadioListTile(
              title: const Text("I am hurt"),
              value: EmergencyType.injured,
              groupValue: selectedType,
              onChanged: (value) => setState(() => selectedType = value),
            ),

            RadioListTile(
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

