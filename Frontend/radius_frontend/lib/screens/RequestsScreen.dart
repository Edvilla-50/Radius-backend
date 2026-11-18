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
  int? _selectedRequestId;
  final Set<int> _respondingIds = {};
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final generation = ++_loadGeneration;
    if (mounted) setState(() => loading = true);
    try {
      final incoming = await ApiService.getIncoming(widget.userId);
      final enriched = await Future.wait(
        incoming.map((req) async {
          final requesterId = (req['requesterId'] as num).toInt();
          try {
            final user = await ApiService.getUser(requesterId);
            return {...req, 'requesterName': user['name']};
          } catch (e) {
            debugPrint('Could not load requester $requesterId: $e');
            return {...req, 'requesterName': 'Someone'};
          }
        }),
      );
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        requests = enriched;
        if (!requests.any(
          (r) => (r['id'] as num).toInt() == _selectedRequestId,
        )) {
          _selectedRequestId = requests.isEmpty
              ? null
              : (requests.first['id'] as num).toInt();
        }
        loading = false;
      });
    } catch (e) {
      debugPrint('Error loading requests: $e');
      if (!mounted || generation != _loadGeneration) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to refresh requests. Please try again.'),
        ),
      );
    }
  }

  Future<void> _respond(dynamic req, bool accepted) async {
    final reqId = (req['id'] as num).toInt();
    if (_respondingIds.contains(reqId)) return;
    final requesterId = (req['requesterId'] as num).toInt();
    final receiverId = (req['receiverId'] as num).toInt();
    final matchId = (req['matchId'] as num).toInt();
    setState(() => _respondingIds.add(reqId));
    try {
      await ApiService.respond(reqId, accepted);
      if (!mounted) return;
      if (accepted) {
        final otherUserId = requesterId == widget.userId
            ? receiverId
            : requesterId;
        AppState().setActiveMatch(matchId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SuggestionsScreen(matchId: matchId, otherUserId: otherUserId),
          ),
        );
      } else {
        await _loadRequests();
      }
    } catch (e) {
      debugPrint('Error responding to request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not respond to request. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _respondingIds.remove(reqId));
    }
  }

  Future<void> _openProfile(dynamic req) async {
    final requesterId = (req['requesterId'] as num).toInt();
    final blocked = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePreviewScreen(userId: requesterId.toString()),
      ),
    );
    if (!mounted) return;
    if (blocked == true) {
      setState(() {
        requests.removeWhere(
          (r) => (r['requesterId'] as num).toInt() == requesterId,
        );
        if (!requests.any(
          (r) => (r['id'] as num).toInt() == _selectedRequestId,
        )) {
          _selectedRequestId = requests.isEmpty
              ? null
              : (requests.first['id'] as num).toInt();
        }
      });
    }
  }

  Widget _actions(dynamic req, {bool vertical = false}) {
    final id = (req['id'] as num).toInt();
    final busy = _respondingIds.contains(id);
    final decline = TextButton(
      onPressed: busy ? null : () => _respond(req, false),
      child: const Text('Decline', style: TextStyle(color: Colors.red)),
    );
    final accept = ElevatedButton(
      onPressed: busy ? null : () => _respond(req, true),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Accept'),
    );
    return vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [accept, decline],
          )
        : Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [decline, accept],
          );
  }

  Widget _requestCard(
    dynamic req, {
    required bool selected,
    required bool wide,
  }) {
    final id = (req['id'] as num).toInt();
    final name = (req['requesterName'] ?? 'Someone').toString();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: selected && wide
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: wide
                  ? () => setState(() => _selectedRequestId = id)
                  : () => _openProfile(req),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const CircleAvatar(child: Icon(Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const Text('Wants to meet up!'),
                        ],
                      ),
                    ),
                    if (wide) const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
            if (!wide)
              Align(alignment: Alignment.centerRight, child: _actions(req)),
          ],
        ),
      ),
    );
  }

  Widget _requestList({required bool wide}) {
    if (requests.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadRequests,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(
              child: Text(
                'No pending requests',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: requests.length,
        itemBuilder: (_, i) {
          final req = requests[i];
          return _requestCard(
            req,
            selected: (req['id'] as num).toInt() == _selectedRequestId,
            wide: wide,
          );
        },
      ),
    );
  }

  Widget _details(dynamic req) {
    final name = (req['requesterName'] ?? 'Someone').toString();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 40,
                child: Icon(Icons.person, size: 40),
              ),
              const SizedBox(height: 18),
              Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('Wants to meet up!', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _openProfile(req),
                icon: const Icon(Icons.person_outline),
                label: const Text('View profile'),
              ),
              const SizedBox(height: 20),
              _actions(req, vertical: true),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh requests',
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                if (!wide) return _requestList(wide: false);
                dynamic selected;
                for (final req in requests) {
                  if ((req['id'] as num).toInt() == _selectedRequestId) {
                    selected = req;
                    break;
                  }
                }
                return SafeArea(
                  child: Row(
                    children: [
                      SizedBox(
                        width: (constraints.maxWidth * 0.42).clamp(
                          280.0,
                          430.0,
                        ),
                        child: _requestList(wide: true),
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: selected == null
                            ? const Center(
                                child: Text('Select a request to view details'),
                              )
                            : _details(selected),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
