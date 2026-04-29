import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfilePreviewScreen extends StatefulWidget {
  final String html;
  const ProfilePreviewScreen({super.key, required this.html});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  late final WebViewController controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..loadHtmlString(widget.html);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Preview')),
      body: WebViewWidget(controller: controller),
    );
  }
}