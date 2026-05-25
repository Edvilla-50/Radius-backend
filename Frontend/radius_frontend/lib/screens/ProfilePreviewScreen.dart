import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String userId;
  const ProfilePreviewScreen({super.key, required this.userId});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(
        'https://www.radius-create.com/api/getProfile.php?id=${widget.userId}',
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Preview')),
      body: WebViewWidget(controller: controller),
    );
  }
}