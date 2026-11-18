import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatScreen extends StatefulWidget {
  final int userId;
  final int otherUserId;

  const ChatScreen({super.key, required this.userId, required this.otherUserId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<dynamic> messages = [];
  final TextEditingController controller = TextEditingController();
  Timer? timer;
  bool _fetching = false;
  bool _sending = false;
  final String _base = 'https://radius-backend-0qv8.onrender.com';

  @override
  void initState() {
    super.initState();
    fetchMessages();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
  }

  @override
  void dispose() {
    timer?.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> fetchMessages() async {
    if (_fetching || !mounted) return;
    _fetching = true;
    try {
      final response = await http.get(
        Uri.parse('$_base/messages/${widget.userId}/${widget.otherUserId}'),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) setState(() => messages = decoded);
      }
    } catch (e) {
      debugPrint('Chat fetch error: $e');
    } finally {
      _fetching = false;
    }
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final response = await http.post(
        Uri.parse('$_base/messages/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.userId,
          'receiverId': widget.otherUserId,
          'content': text,
        }),
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        controller.clear();
        await fetchMessages();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send message')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderId']?.toString() == widget.userId.toString();
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 480),
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.orange : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (msg['content'] ?? '').toString(),
                            style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onSurface),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => sendMessage(),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Send message',
                        icon: const Icon(Icons.send, color: Colors.orange),
                        onPressed: _sending ? null : sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
