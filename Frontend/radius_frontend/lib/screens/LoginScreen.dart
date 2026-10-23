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
        Uri.parse("https://radius-backend-0qv8.onrender.com/user/fcm-token"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "fcmToken": token,
        }),
      );
    } catch (e) {
      debugPrint("FCM token error: $e");//debug
    }
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Please enter email and password");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Long timeout: the server may need time to wake up after being idle.
      final response = await http
          .post(
            Uri.parse("https://radius-backend-0qv8.onrender.com/user/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "email": email,
              "password": password,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;
      setState(() => loading = false);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final int userId = json["userId"];
        final String name = json["name"];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt("userId", userId);
        await prefs.setString("name", name);
        await _sendFcmToken(userId);//send to backend

        if (!mounted) return;
        // Navigate to home
        Navigator.pushReplacementNamed(
          context,
          "/home",
          arguments: {"userId": userId, "name": name},
        );
      } else {
        setState(() => errorMessage = "Invalid email or password");
      }
    } catch (e) {
      debugPrint("Login error: $e");
      if (!mounted) return;
      setState(() {
        loading = false;
        errorMessage = "Could not reach the server. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Input colors are set explicitly so the fields are readable in both
    // light and dark mode (the fields have a white fill).
    const inputTextStyle = TextStyle(color: Colors.black87);
    const labelStyle = TextStyle(color: Colors.black54);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 350,
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
                  "RADIUS",
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
                  style: inputTextStyle,
                  cursorColor: Colors.black87,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: "Email",
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
                  style: inputTextStyle,
                  cursorColor: Colors.black87,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Login"),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegistrationScreen(),
                      ),
                    );
                  },
                  child: const Text("Create an account"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}