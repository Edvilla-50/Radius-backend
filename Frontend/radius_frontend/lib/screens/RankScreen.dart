import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';

class RankScreen extends StatefulWidget {
  final int userId;
  const RankScreen({super.key, required this.userId});

  @override
  State<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends State<RankScreen> {
  List<Map<String, dynamic>> _interests = [];
  bool _loading = true;
  bool _saving = false;
  double _preferredDistance = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getUser(widget.userId);
      if (!mounted) return;
      setState(() {
        _interests = List<Map<String, dynamic>>.from(user['interests']);
        // Preserve the backend's existing field spelling.
        _preferredDistance =
            ((user['perferredDistance'] as num?)?.toDouble() ?? 1.0).clamp(
              1.0,
              5.0,
            );
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveInterests() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final ids = _interests.map((i) => (i['id'] as num).toInt()).toList();
      await ApiService.updateInterests(widget.userId, ids);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Interests Updated!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to Save')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showAddInterestDialog() async {
    try {
      final allInterests = await ApiService.getAllInterests();
      if (!mounted) return;
      final currentIds = _interests.map((i) => i['id']).toSet();
      final available = allInterests
          .where((i) => !currentIds.contains(i['id']))
          .toList();
      if (available.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All interests already added!')),
        );
        return;
      }
      String query = '';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final filtered = available
                .where(
                  (i) => i['name'].toString().toLowerCase().contains(
                    query.toLowerCase(),
                  ),
                )
                .toList();
            return AlertDialog(
              title: const Text('Add Interest'),
              content: SizedBox(
                width: 440,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search interests...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => setDialogState(() => query = val),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matches found'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final interest = filtered[index];
                                return ListTile(
                                  title: Text(interest['name'].toString()),
                                  onTap: () {
                                    Navigator.pop(dialogContext);
                                    if (mounted)
                                      setState(
                                        () => _interests.add(
                                          Map<String, dynamic>.from(interest),
                                        ),
                                      );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not load interests')));
    }
  }

  Widget _distanceSettings() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        'Meet distance: ${_preferredDistance.toStringAsFixed(1)} mi',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Slider(
        value: _preferredDistance,
        min: 1.0,
        max: 5.0,
        divisions: 8,
        label: '${_preferredDistance.toStringAsFixed(1)} mi',
        onChanged: (val) => setState(() => _preferredDistance = val),
        onChangeEnd: (val) =>
            ApiService.updatePreferredDistance(widget.userId, val),
      ),
    ],
  );

  Widget _reorderList() => DragAndDropLists(
    children: [
      DragAndDropList(
        children: _interests.asMap().entries.map((entry) {
          final i = entry.key;
          final interest = entry.value;
          return DragAndDropItem(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              title: Text(interest['name'].toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _interests.removeAt(i)),
                  ),
                  const Icon(Icons.drag_handle),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ],
    onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
      setState(() {
        final item = _interests.removeAt(oldItemIndex);
        _interests.insert(newItemIndex.clamp(0, _interests.length), item);
      });
    },
    onListReorder: (oldIndex, newIndex) {},
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text(
          'My Trait Stack',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : TextButton(
                  onPressed: _saveInterests,
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInterestDialog,
        child: const Icon(Icons.add),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          if (wide) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 320,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Drag to reorder by importance!',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _distanceSettings(),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 12,
                          right: 12,
                          bottom: 12,
                        ),
                        child: _reorderList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Drag to reorder by importance!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    _distanceSettings(),
                  ],
                ),
              ),
              Expanded(child: _reorderList()),
            ],
          );
        },
      ),
    );
  }
}
