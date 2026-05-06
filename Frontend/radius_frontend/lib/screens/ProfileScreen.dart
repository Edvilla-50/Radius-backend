import 'package:flutter/material.dart';
import '../services/ApiService.dart';
import 'ProfilePreviewScreen.dart';

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
          child: Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: color == Colors.white ? Colors.black : Colors.white,
            )),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.preview),
            onPressed: () async{
              final html = await ApiService.getProfileHtml(widget.userId);
              Navigator.push(
                context,
                MaterialPageRoute( 
               builder: (context)=>ProfilePreviewScreen(html: html)
                ),
              );
            },
          ),
          _saving
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: Colors.white),
              )
            : IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveProfile,
              ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose a Template',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          ],
        ),
      ),
    );
  }
}