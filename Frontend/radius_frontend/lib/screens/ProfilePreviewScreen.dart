
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ApiService.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String userId;

  // Set true when displaying this profile beside the map.
  final bool embedded;

  // Called after successfully blocking a user in embedded mode.
  final VoidCallback? onBlocked;

  const ProfilePreviewScreen({
    super.key,
    required this.userId,
    this.embedded = false,
    this.onBlocked,
  });

  @override
  State<ProfilePreviewScreen> createState() =>
      _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState
    extends State<ProfilePreviewScreen> {
  late final WebViewController controller;

  int? _myUserId;
  String _selectedReason = "Inappropriate Profile";
  bool _submittingReport = false;
  bool _submittingBlock = false;
  bool _loadingProfile = true;
  String? _profileError;

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
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loadingProfile = true;
                _profileError = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loadingProfile = false);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _loadingProfile = false;
                _profileError = "Unable to load profile.";
              });
            }
          },
        ),
      );

    _loadProfile();
    _loadMyUserId();
  }

  void _loadProfile() {
    final uri = Uri.https(
      'www.radius-create.com',
      '/api/getProfile.php',
      {'id': widget.userId},
    );

    controller.loadRequest(uri);
  }

  @override
  void didUpdateWidget(covariant ProfilePreviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Important for foldable layouts:
    // Update the WebView when a different user is selected
    // without recreating the entire profile panel.
    if (oldWidget.userId != widget.userId) {
      _loadProfile();
    }
  }

  Future<void> _loadMyUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt("userId");

    if (mounted) {
      setState(() => _myUserId = id);
    }
  }

  void _openReportDialog() {
    if (_myUserId == null || _submittingReport) return;

    final detailsController = TextEditingController();
    String reason = _reportReasons.first;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Report this user"),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Reason",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: reason,
                        isExpanded: true,
                        items: _reportReasons
                            .map(
                              (r) => DropdownMenuItem(
                                value: r,
                                child: Text(r),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => reason = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Details (optional)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: detailsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText:
                              "Anything else we should know?",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    final details =
                        detailsController.text.trim();

                    Navigator.pop(dialogContext);
                    _submitReport(reason, details);
                  },
                  child: const Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => detailsController.dispose());
  }

  void _openBlockDialog() {
    if (_myUserId == null || _submittingBlock) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Block this user?"),
        content: const Text(
          "They won't appear in your scans and "
          "you won't appear in theirs.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitBlock();
            },
            child: const Text(
              "Block",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitBlock() async {
    if (_myUserId == null || _submittingBlock) return;

    final blockedId = int.tryParse(widget.userId);
    if (blockedId == null) return;

    setState(() => _submittingBlock = true);

    try {
      await ApiService.blockUser(_myUserId!, blockedId);

      if (!mounted) return;

      if (widget.embedded) {
        widget.onBlocked?.call();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to block user."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingBlock = false);
      }
    }
  }

  Future<void> _submitReport(
    String reason,
    String details,
  ) async {
    if (_myUserId == null || _submittingReport) return;

    final reportedUserId = int.tryParse(widget.userId);
    if (reportedUserId == null) return;

    setState(() => _submittingReport = true);

    try {
      await ApiService.reportUser(
        _myUserId!,
        reportedUserId,
        reason,
        details,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Report submitted. Thank you."),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Unable to submit report."),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submittingReport = false);
      }
    }
  }

  Widget _buildProfileBody() {
    return Stack(
      children: [
        Positioned.fill(
          child: WebViewWidget(controller: controller),
        ),

        if (_loadingProfile)
          const Center(
            child: CircularProgressIndicator(),
          ),

        if (_profileError != null)
          Positioned.fill(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(_profileError!),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loadProfile,
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      IconButton(
        icon: const Icon(Icons.block),
        tooltip: "Block user",
        onPressed:
            _myUserId == null || _submittingBlock
                ? null
                : _openBlockDialog,
      ),
      IconButton(
        icon: const Icon(Icons.flag_outlined),
        tooltip: "Report user",
        onPressed:
            _myUserId == null || _submittingReport
                ? null
                : _openReportDialog,
      ),
    ];

    // Embedded mode for unfolded foldable screens.
    // No nested Scaffold, allowing the parent screen
    // to display this alongside the map.
    if (widget.embedded) {
      return Column(
        children: [
          Material(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerLow,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Profile Preview",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ...actions,
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildProfileBody()),
        ],
      );
    }

    // Regular phone mode: preserve normal navigation.
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile Preview"),
        actions: actions,
      ),
      body: _buildProfileBody(),
    );
  }
}
