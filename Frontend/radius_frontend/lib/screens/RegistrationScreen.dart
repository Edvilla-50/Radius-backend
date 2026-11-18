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

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  void _showEula() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terms of Use'),
        content: const SingleChildScrollView(
          child: Text(
            'By using Radius, you agree to the following:\n\n'
            '1. NO OBJECTIONABLE CONTENT\n'
            'You must not post, share, or display any content that is offensive, '
            'abusive, hateful, threatening, or otherwise objectionable. Violations '
            'will result in immediate account removal.\n\n'
            '2. NO ABUSIVE BEHAVIOR\n'
            'Harassment, bullying, stalking, or any abusive behavior toward other '
            'users is strictly prohibited.\n\n'
            '3. REAL IDENTITY\n'
            'You must not impersonate others or create fake accounts.\n\n'
            '4. LOCATION SHARING\n'
            'By using the scan feature, you consent to sharing your location with '
            'nearby users. You may hide yourself at any time using Ghost Mode.\n\n'
            '5. REPORTING\n'
            'You agree to report any objectionable content or abusive users using '
            'the in-app reporting tools.\n\n'
            '6. ENFORCEMENT\n'
            'Radius reserves the right to remove any content and terminate any '
            'account that violates these terms at our sole discretion. '
            'Radius reviews all reports within 24 hours and will remove objectionable '
            'content and terminate offending accounts promptly. A profanity filter is '
            'applied to all messages automatically.\n\n'
            'By creating an account, you confirm you have read, understood, and '
            'agree to these Terms of Use.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
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
      setState(() => errorMessage = 'All fields are required');
      return;
    }

    if (!_eulaAccepted) {
      setState(() => errorMessage = 'You must agree to the Terms of Use');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final response = await http
          .post(
            Uri.parse('https://radius-backend-0qv8.onrender.com/user/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'emergencyPhone': phone,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (!mounted) return;
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        setState(() => errorMessage = 'Registration failed');
      }
    } catch (e) {
      debugPrint('Registration error: $e');
      if (!mounted) return;
      setState(
        () => errorMessage = 'Could not reach the server. Please try again.',
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _registrationForm() {
    final colors = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create your account',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Join Radius and meet people nearby.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.error, fontSize: 14),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (_) {
                  if (!loading) register();
                },
                decoration: const InputDecoration(
                  labelText: 'Emergency Contact Number',
                  hintText: '12223334444',
                  prefixText: '+',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _eulaAccepted,
                    onChanged: loading
                        ? null
                        : (value) =>
                              setState(() => _eulaAccepted = value ?? false),
                  ),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'I agree to the ',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: _showEula,
                          child: const Text('Terms of Use'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: loading ? null : register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            final form = _registrationForm();
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.people_alt_rounded,
                                  size: 100,
                                  color: Colors.orange,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Welcome to RADIUS',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineMedium,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Discover new connections and meet in real life.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: Center(child: form)),
                      ],
                    )
                  : Center(child: form),
            );
          },
        ),
      ),
    );
  }
}
