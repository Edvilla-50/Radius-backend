import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ApiService.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String userId;
  const ProfilePreviewScreen({super.key, required this.userId});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  late final WebViewController controller;

  int? _myUserId;
  String _selectedReason = "Inappropriate Profile";
  bool _submittingReport = false;

  final List<String> _reportReasons = [
    "Inappropriate Profile",
    "Harassment",
    "Safety Concern",
    "Fake Account",
    "Other",
  ];

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
        'https://www.radius-create.com/api/getProfile.php?id=${widget.userId}',
      ));

    _loadMyUserId();
  }

  Future<void> _loadMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");
    if (mounted) setState(() => _myUserId = id);
  }

  void _openReportDialog() {
    if (_myUserId == null) return;

    final detailsController = TextEditingController();
    _selectedReason = _reportReasons.first;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Report this user"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reason", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedReason,
                    isExpanded: true,
                    items: _reportReasons
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => _selectedReason = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text("Details (optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "Anything else we should know?",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: _submittingReport
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await _submitReport(_selectedReason, detailsController.text.trim());
                        },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport(String reason, String details) async {
    if (_myUserId == null) return;

    final reportedUserId = int.tryParse(widget.userId);
    if (reportedUserId == null) return;

    setState(() => _submittingReport = true);

    try {
      await ApiService.reportUser(_myUserId!, reportedUserId, reason, details);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report submitted. Thank you.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("You can't report yourself.")),
        );
      }
    } finally {
      if (mounted) setState(() => _submittingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: "Report user",
            onPressed: _myUserId == null ? null : _openReportDialog,
          ),
        ],
      ),
      body: WebViewWidget(controller: controller),
    );
  }
}