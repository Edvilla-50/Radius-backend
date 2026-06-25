import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import '../state/AppState.dart';
import 'SuggestionsScreen.dart';
import 'ProfilePreviewScreen.dart';

class RequestsScreen extends StatefulWidget {
  final int userId;
  const RequestsScreen({super.key, required this.userId});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  List<dynamic> requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    try {
      final incoming = await ApiService.getIncoming(widget.userId);
      final enriched = await Future.wait(incoming.map((req) async {
        final requesterId = (req["requesterId"] as num).toInt();
        final user = await ApiService.getUser(requesterId);
        return {
          ...req,
          "requesterName": user["name"],
        };
      }));
      setState(() {
        requests = enriched;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      debugPrint("Error loading requests: $e");
    }
  }

  Future<void> _respond(dynamic req, bool accepted) async {
    final reqId = (req["id"] as num).toInt();
    final requesterId = (req["requesterId"] as num).toInt();
    final receiverId = (req["receiverId"] as num).toInt();
    final matchId = (req["matchId"] as num).toInt();

    await ApiService.respond(reqId, accepted);

    if (accepted) {
      if (!mounted) return;
      final otherUserId =
          requesterId == widget.userId ? receiverId : requesterId;

      AppState().setActiveMatch(matchId);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestionsScreen(
            matchId: matchId,
            otherUserId: otherUserId,
          ),
        ),
      );
    } else {
      _loadRequests();
    }
  }

  Future<void> _openProfile(dynamic req) async {
    final requesterId = (req["requesterId"] as num).toInt();
    final blocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePreviewScreen(
          userId: requesterId.toString(),
        ),
      ),
    );
    if (blocked == true && mounted) {
      setState(() {
        requests.removeWhere(
          (r) => (r["requesterId"] as num).toInt() == requesterId,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Requests"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        "No pending requests",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, i) {
                      final req = requests[i];
                      final name = req["requesterName"] ?? "Someone";
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => _openProfile(req),
                                borderRadius: BorderRadius.circular(24),
                                child: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _openProfile(req),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      const Text(
                                        "Wants to meet up!",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () => _respond(req, false),
                                child: const Text("Decline",
                                    style: TextStyle(color: Colors.red)),
                              ),
                              ElevatedButton(
                                onPressed: () => _respond(req, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange),
                                child: const Text("Accept"),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}