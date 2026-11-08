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

/// Returning resident: email and password checked against the backend.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onSignedIn});

  final void Function(String email, String? name) onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
            Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': _email.text.trim(),
              'password': _password.text,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          _busy = false;
          _error = apiMessage(
            response,
            fallback: response.statusCode == 401
                ? 'Invalid email or password.'
                : 'Login failed. Try again.',
          );
        });
        return;
      }

      // The login response carries the stored profile, so the session and the
      // profile it will display are saved together.
      final profile = UserProfile.tryParse(response.body);
      final account = await LocalAccountStore().saveConfirmedProfile(
        name: profile?.fullName ?? '',
        email: profile?.email ?? _email.text,
        password: _password.text,
        mobile: profile?.phone ?? '',
        address: profile?.address ?? '',
      );

      if (!mounted) return;
      if (account == null) {
        setState(() {
          _busy = false;
          _error = 'Signed in, but this device could not store the session.';
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
        _error = 'Login failed. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log In')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const AuthHeading(
              title: 'Welcome Back',
              subtitle: 'Log in to pick up the reports you have already filed.',
            ),
            const SizedBox(height: 26),
            AuthField(
              label: 'Email Address',
              controller: _email,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      hintText: 'Your password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 19,
                        ),
                      ),
                    ),
                    validator: validatePassword,
                  ),
                ],
              ),
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
                  : const Text('Log In'),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'By logging in, you agree to our Terms of Service and Privacy Policy.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
