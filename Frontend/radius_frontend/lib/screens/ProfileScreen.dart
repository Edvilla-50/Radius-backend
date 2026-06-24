import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/ApiService.dart';
import 'ProfilePreviewScreen.dart';
import 'LoginScreen.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;
  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _selectedTemplate = 'minimal';
  String _bio = '';
  String _quote = '';
  bool _saving = false;
  bool _deletingAccount = false;

  String _generateHtml() {
    final templates = {
      'minimal': '''
        <html><body style="font-family: Arial; background: white; padding: 20px;">
          <h1 style="color: #333;">My Profile</h1>
          <p style="color: #666;">$_bio</p>
          <blockquote style="color: #999; font-style: italic;">"$_quote"</blockquote>
        </body></html>
      ''',
      'dark': '''
        <html><body style="font-family: Arial; background: #1a1a2e; padding: 20px; color: white;">
          <h1 style="color: #e94560;">My Profile</h1>
          <p style="color: #ccc;">$_bio</p>
          <blockquote style="color: #e94560; font-style: italic;">"$_quote"</blockquote>
        </body></html>
      ''',
      'sunset': '''
        <html><body style="font-family: Arial; background: linear-gradient(#ff6b6b, #feca57); padding: 20px;">
          <h1 style="color: white; text-shadow: 2px 2px 4px rgba(0,0,0,0.5);">My Profile</h1>
          <p style="color: white;">$_bio</p>
          <blockquote style="color: #fff; font-style: italic;">"$_quote"</blockquote>
        </body></html>
      ''',
      'gamer': '''
        <html><body style="font-family: 'Courier New'; background: #0d0d0d; padding: 20px; color: #00ff00;">
          <h1 style="color: #00ff00; text-shadow: 0 0 10px #00ff00;">My Profile</h1>
          <p style="color: #00cc00;">$_bio</p>
          <blockquote style="color: #ff00ff; font-style: italic;">"$_quote"</blockquote>
        </body></html>
      ''',
      'nature': '''
        <html><body style="font-family: Georgia; background: #e8f5e9; padding: 20px;">
          <h1 style="color: #2e7d32;">My Profile</h1>
          <p style="color: #388e3c;">$_bio</p>
          <blockquote style="color: #66bb6a; font-style: italic;">"$_quote"</blockquote>
        </body></html>
      ''',
    };
    return templates[_selectedTemplate] ?? templates['minimal']!;
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateProfileHtml(widget.userId, _generateHtml());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile Saved!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save profile!')),
      );
    }
    setState(() => _saving = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    // First confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all your data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Second confirmation — makes it hard to do by accident
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
          'Your profile, matches, and all data will be permanently deleted. There is no way to recover your account after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete My Account',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    setState(() => _deletingAccount = true);

    try {
      await ApiService.deleteAccount(widget.userId);

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  Widget _templateCard(String id, String label, Color color) {
    final isSelected = _selectedTemplate == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedTemplate = id),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: color == Colors.white ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('My Profile', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfilePreviewScreen(
                    userId: widget.userId.toString(),
                  ),
                ),
              );
            },
            child: const Text('Preview', style: TextStyle(color: Colors.white)),
          ),
          _saving
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(color: Colors.orange),
                )
              : TextButton(
                  onPressed: _saveProfile,
                  child: const Text('Save', style: TextStyle(color: Colors.white)),
                ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log Out',
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "This is a simple in‑app editor.\nFor full customization, visit www.radius-create.com",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Text(
              'Choose a Template',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _templateCard('minimal', '☀️ Minimal', Colors.white),
                  _templateCard('dark', '🌙 Dark', const Color(0xff1a1a2e)),
                  _templateCard('sunset', '🌅 Sunset', Colors.orange),
                  _templateCard('gamer', '🎮 Gamer', Colors.black),
                  _templateCard('nature', '🌿 Nature', const Color(0xffe8f5e9)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Bio',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Tell people about yourself!',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _bio = val),
            ),
            const SizedBox(height: 20),
            const Text('Favorite Quote',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'What\'s your favorite quote?',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => setState(() => _quote = val),
            ),

            // ── DELETE ACCOUNT ──────────────────────────────────────
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deleting your account is permanent and cannot be undone.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: _deletingAccount
                  ? const Center(child: CircularProgressIndicator(color: Colors.red))
                  : OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}