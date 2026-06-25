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
  bool _eulaAccepted = false;
  String? errorMessage;

  void _showEula() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Terms of Use"),
        content: SingleChildScrollView(
          child: const Text(
            "By using Radius, you agree to the following:\n\n"
            "1. NO OBJECTIONABLE CONTENT\n"
            "You must not post, share, or display any content that is offensive, "
            "abusive, hateful, threatening, or otherwise objectionable. Violations "
            "will result in immediate account removal.\n\n"
            "2. NO ABUSIVE BEHAVIOR\n"
            "Harassment, bullying, stalking, or any abusive behavior toward other "
            "users is strictly prohibited.\n\n"
            "3. REAL IDENTITY\n"
            "You must not impersonate others or create fake accounts.\n\n"
            "4. LOCATION SHARING\n"
            "By using the scan feature, you consent to sharing your location with "
            "nearby users. You may hide yourself at any time using Ghost Mode.\n\n"
            "5. REPORTING\n"
            "You agree to report any objectionable content or abusive users using "
            "the in-app reporting tools.\n\n"
            "6. ENFORCEMENT\n"
            "Radius reserves the right to remove any content and terminate any "
            "account that violates these terms at our sole discretion.\n\n"
            "By creating an account, you confirm you have read, understood, and "
            "agree to these Terms of Use.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final phone = phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty) {
      setState(() => errorMessage = "All fields are required");
      return;
    }

    if (!_eulaAccepted) {
      setState(() => errorMessage = "You must agree to the Terms of Use");
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
      appBar: AppBar(title: const Text("Create Account")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14)),
              ),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Name",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: "Emergency Contact Number",
                hintText: "12223334444",
                prefixText: "+",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // EULA checkbox
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: _eulaAccepted,
                  onChanged: (val) =>
                      setState(() => _eulaAccepted = val ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _showEula,
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black87, fontSize: 14),
                        children: [
                          TextSpan(text: "I agree to the "),
                          TextSpan(
                            text: "Terms of Use",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : register,
              child: loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}