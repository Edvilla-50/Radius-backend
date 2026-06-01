import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool loading = false;
  String? errorMessage;

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() => errorMessage = "All fields are required");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    final body = {
      "name": name,
      "email": email,
      "password": password,
      "emergencyPhone": phone,
    };

    final response = await http.post(
      Uri.parse("https://radius-backend-0qv8.onrender.com/user/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    setState(() => loading = false);

    if (response.statusCode == 200) {
      Navigator.pop(context);
    } else {
      setState(() => errorMessage = "Registration failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 14)),
              ),

            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 12),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 12),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: "Emergency Contact Number",
                hintText: "12223334444",
                prefixText: "+",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : register,
              child: loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}