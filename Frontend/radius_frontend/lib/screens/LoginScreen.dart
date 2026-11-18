import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'RegistrationScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendFcmToken(int userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      final token = await messaging.getToken();
      if (token == null) return;

      await http.post(
        Uri.parse('https://radius-backend-0qv8.onrender.com/user/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'fcmToken': token}),
      );
    } catch (e) {
      debugPrint('FCM token error: $e');
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Please enter email and password');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://radius-backend-0qv8.onrender.com/user/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;
      setState(() => loading = false);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final int userId = json['userId'];
        final String name = json['name'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userId);
        await prefs.setString('name', name);
        await _sendFcmToken(userId);

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/home',
          arguments: {'userId': userId, 'name': name},
        );
      } else {
        if (!mounted) return;
        setState(() => errorMessage = 'Invalid email or password');
      }
    } catch (e) {
      debugPrint('Login error: $e');
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = 'Could not reach the server. Please try again.';
      });
    }
  }

  Widget _buildLoginForm() {
    const inputTextStyle = TextStyle(color: Colors.black87);
    const labelStyle = TextStyle(color: Colors.black54);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'RADIUS',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),
          if (errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
          TextField(
            controller: emailController,
            enabled: !loading,
            style: inputTextStyle,
            cursorColor: Colors.black87,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: labelStyle,
              floatingLabelStyle: const TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passwordController,
            enabled: !loading,
            style: inputTextStyle,
            cursorColor: Colors.black87,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!loading) login();
            },
            decoration: InputDecoration(
              labelText: 'Password',
              labelStyle: labelStyle,
              floatingLabelStyle: const TextStyle(color: Colors.black87),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: loading ? null : login,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: const Size(double.infinity, 48),
            ),
            child: loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text('Login'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: loading
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrationScreen(),
                      ),
                    );
                  },
            child: const Text('Create an account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 760;
            final horizontalPadding = wide ? 32.0 : 16.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 960 : 400),
                      child: wide
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 40),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.people_alt_outlined,
                                          color: Colors.orange,
                                          size: 72,
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          'Meet people nearby.',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          'Sign in to Radius and discover real connections.',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 400, child: _buildLoginForm()),
                              ],
                            )
                          : _buildLoginForm(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
