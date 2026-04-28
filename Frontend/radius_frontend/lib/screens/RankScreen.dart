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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getUser(widget.userId);
      setState(() {
        _interests = List<Map<String, dynamic>>.from(user['interests']);
        _loading = false;
      });
    } catch (e) {
      print('Error loading user: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveInterests() async {
    setState(() => _saving = true);
    try {
      final ids = _interests.map((i) => i['id'] as int).toList();
      await ApiService.updateInterests(widget.userId, ids);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interests Updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to Save')),
      );
    }
    setState(() => _saving = false);
  }

  Future<void> _showInterestDetailsDialog(Map<String, dynamic> interest) async{
    String? difficulty;
    bool moneyNeeded = false;
    bool disAccessible = false;
    String meetUpTime = '';

    await showDialog(
      context: context,
      builder:(context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text ('Customize ${interest['name']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children:[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Difficulty'),
                items: ['Easy', 'Medium', 'Hard']
                .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                .toList(),
                onChanged: (val) => setDialogState(() => difficulty = val),
              ),
              SwitchListTile(
                title: const Text('Costs Money'),
                value: moneyNeeded,
                onChanged: (val)=> setDialogState(()=> moneyNeeded = val),
              ),
              SwitchListTile(
                title: const Text('Accessible to people with disabilities'),
                value: disAccessible,
                onChanged: (val) => setDialogState(() => disAccessible = val),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Meet up Time (e.g evenings)'),
                onChanged: (val) => meetUpTime = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text ('Cancel'),
            ),
           ElevatedButton(
              onPressed: () {
                setState(() {
                  _interests.add({
                    ...interest,
                    'difficulty': difficulty,
                    'moneyNeeded': moneyNeeded,
                    'disAccessible': disAccessible,
                    'meetUpTime': meetUpTime,
                  });
                });
                Navigator.pop(context);
              },
              child: const Text('Add'), // ✅
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddInterestDialog() async {
    final allInterests = await ApiService.getAllInterests();
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interest'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: available.length,
            itemBuilder: (context, index) {
              final interest = available[index];
              return ListTile(
                title: Text(interest['name']),
                onTap: () {
                  Navigator.pop(context);
                  _showInterestDetailsDialog(interest);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trait Stack'),
        actions: [
          _saving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Colors.white),
              )
            : IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveInterests,
              ),
        ],
      ),
      floatingActionButton: FloatingActionButton(  // ✅ add interest button
        onPressed: _showAddInterestDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Drag to reorder by importance!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: DragAndDropLists(
              children: [
                DragAndDropList(
                  children: _interests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final interest = entry.value;
                    return DragAndDropItem(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(interest['name']),
                        trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _interests.removeAt(index);
                              });
                            },
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
                  _interests.insert(newItemIndex, item);
                });
              },
              onListReorder: (oldIndex, newIndex) {},
            ),
          ),
        ],
      ),
    );
  }
}