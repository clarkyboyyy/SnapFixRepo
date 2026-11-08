import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../apiconfig.dart';
import '../data/api_message.dart';
import '../data/local_account_store.dart';
import '../data/user_profile.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

// 1. Email Validator
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }

  String trimmedValue = value.trim();

  // This regular expression strictly allows only Gmail addresses (@gmail.com)
  bool isGmail = RegExp(
    r"^[a-zA-Z0-9._%+-]+@gmail\.com$",
    caseSensitive: false,
  ).hasMatch(trimmedValue);

  if (!isGmail) {
    return 'Invalid Email. Only Gmail addresses are allowed.';
  }

  return null; // Valid!
}

// 2. Password Validator (8+ chars, 1 uppercase, 1 lowercase, 1 number)
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }

  bool isValidFormat = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$')
      .hasMatch(value);

  if (!isValidFormat) {
    return 'Must be at least 8 characters with 1 uppercase, 1 lowercase, and 1 number';
  }

  return null; // Valid!
}

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
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _showPassword = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
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
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': _name.text.trim(),
              'email': _email.text.trim(),
              'password': _password.text,
              'phone': _phone.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200 && response.statusCode != 201) {
        setState(() {
          _busy = false;
          _error = apiMessage(
            response,
            fallback: 'Registration failed (HTTP ${response.statusCode}).',
          );
        });
        return;
      }

      // Keep the details the backend confirmed so the profile is populated
      // before the screen is opened, even when the network drops afterwards.
      final profile = UserProfile.tryParse(response.body);
      final account = await LocalAccountStore().saveConfirmedProfile(
        name: _prefer(profile?.fullName, _name.text),
        email: _prefer(profile?.email, _email.text),
        password: _password.text,
        mobile: _prefer(profile?.phone, _phone.text),
      );

      if (!mounted) return;
      if (account == null) {
        setState(() {
          _busy = false;
          _error = 'Account created, but it could not be saved on this device.';
        });
        return;
      }

      widget.onSignedIn(account.email, account.name);
      setState(() => _busy = false);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'The server took too long to respond. Try again.';
      });
    } on http.ClientException {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Cannot connect to server. Is the C# backend running?';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Registration failed. Try again.';
      });
    }
  }

  static String _prefer(String? fromServer, String typed) {
    final value = fromServer?.trim() ?? '';
    return value.isEmpty ? typed.trim() : value;
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
              label: 'Mobile Number (optional)',
              controller: _phone,
              hint: 'e.g. 0917 123 4567',
              keyboardType: TextInputType.phone,
              validator: validateMobile,
            ),
            AuthField(
              label: 'Password',
              controller: _password,
              hint: 'At least 8 characters',
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
