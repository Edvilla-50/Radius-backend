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

    // Prevent WebView crash by ensuring HTML is never empty
    final safeHtml = widget.html.isNotEmpty
        ? widget.html
        : """
          <html>
            <body style="font-family: Arial; padding: 20px;">
              <h2>No Profile Found</h2>
              <p>You haven't created a profile yet.</p>
              <p>Please customize your profile in the Profile Editor.</p>
            </body>
          </html>
        """;

    controller = WebViewController()
      ..loadHtmlString(safeHtml);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Preview')),
      body: WebViewWidget(controller: controller),
    );
  }
}
