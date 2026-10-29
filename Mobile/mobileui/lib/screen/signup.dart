import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// New resident: name, email and a confirmed password.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.onSignedIn});

  final void Function(String email, String? name) onSignedIn;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // 1. Point to your local C# Backend API
      var url = Uri.parse('http://localhost:5141/api/auth/register');

      // 2. Send the registration data to C#
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "password": _password.text,
          "fullName": _name.text.trim()
        }),
      );

      if (!mounted) return;

      // 3. Handle Success (Status 200 OK or 201 Created)
      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSignedIn(_email.text.trim(), _name.text.trim());
        setState(() => _busy = false);
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // 4. Handle backend rejection (e.g., email already exists)
        setState(() {
          _busy = false;
          _error = "Registration failed: ${response.body}";
        });
      }
    } catch (e) {
      // 5. Handle Network/Connection Errors
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = "Cannot connect to server. Is the C# backend running?";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const AuthHeading(
              title: 'Create Account',
              subtitle:
                  'Save your reports under one profile so the barangay can '
                  'follow up with you.',
            ),
            const SizedBox(height: 26),
            AuthField(
              label: 'Full Name',
              controller: _name,
              hint: 'e.g. Mark Oliver Anin ',
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            AuthField(
              label: 'Email Address',
              controller: _email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            AuthField(
              label: 'Password',
              controller: _password,
              hint: 'At least 6 characters',
              obscure: !_showPassword,
              validator: validatePassword,
            ),
            AuthField(
              label: 'Confirm Password',
              controller: _confirm,
              hint: 'Re-enter your password',
              obscure: !_showPassword,
              validator: (v) =>
                  v == _password.text ? null : 'Passwords do not match',
            ),
            Row(
              children: [
                Checkbox(
                  value: _showPassword,
                  onChanged: (v) => setState(() => _showPassword = v ?? false),
                  activeColor: AppTheme.pink,
                ),
                const Expanded(
                  child: Text(
                    'Show passwords',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Account'),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
