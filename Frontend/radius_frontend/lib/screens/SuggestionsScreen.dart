import 'package:flutter/material.dart';
import '../services/ApiService.dart';

class SuggestionsScreen extends StatefulWidget {
  final int userId;
  final int matchId;

  const SuggestionsScreen({
    super.key,
    required this.userId,
    required this.matchId,
  });

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  bool _loading = true;
  dynamic _suggestions;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final res = await ApiService().getInterestSuggestions(
        widget.userId,
        widget.matchId,
      );
      print("RAW RESPONSE: $_suggestions");
      print("TYPE: ${_suggestions.runtimeType}");
      setState(() {
        _suggestions = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading suggestions: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final results = (_suggestions?["results"] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Suggested Places"),
        backgroundColor: Colors.green,
      ),
      body: results.isEmpty
          ? const Center(
              child: Text(
                "No suggestions found! :(",
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final place = results[index];
                final name = place['name'] ?? "Unknown Place";
                final address =
                    place["location"]?["formatted_address"] ?? "No Address";

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.place, color: Colors.blue),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(address),
                  ),
                );
              },
            ),
    );
  }
}
