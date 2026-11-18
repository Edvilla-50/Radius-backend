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
  String note = '';

  Future<void> sendAlert() async {
    if (selectedType == null || isSending) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Emergency alert sent')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to send alert')));
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Assistance')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Select your situation:',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      RadioGroup<EmergencyType>(
                        groupValue: selectedType,
                        onChanged: (value) =>
                            setState(() => selectedType = value),
                        child: const Column(
                          children: [
                            RadioListTile<EmergencyType>(
                              title: Text('I feel unsafe'),
                              value: EmergencyType.unsafe,
                            ),
                            RadioListTile<EmergencyType>(
                              title: Text('I am hurt'),
                              value: EmergencyType.injured,
                            ),
                            RadioListTile<EmergencyType>(
                              title: Text('I need to be picked up'),
                              value: EmergencyType.pickup,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Optional note',
                          border: OutlineInputBorder(),
                        ),
                        minLines: 1,
                        maxLines: 4,
                        onChanged: (value) => note = value,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isSending ? null : sendAlert,
                        child: isSending
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send Alert'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
