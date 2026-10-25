import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widget/brand.dart';
import 'login.dart';
import 'signup.dart';

/// Sign-in / sign-up entry screen. Reports the signed-in resident back to the
/// caller so the app shell owns its own auth state.
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key, required this.onSignedIn});

  final void Function(String email, String? name) onSignedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: Brand(logoSize: 52)),
              const SizedBox(height: 34),
              const Center(
                child: Text(
                  'Welcome to SnapFix',
                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Connect your account to keep every report in one place '
                  'across your devices.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.muted, height: 1.45),
                ),
              ),
              const SizedBox(height: 30),
              OutlinedButton.icon(
                onPressed: () => _showGoogleNotice(context),
                icon: const Icon(Icons.mail_outline, size: 19),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    _open(context, SignupPage(onSignedIn: onSignedIn)),
                child: const Text('Create Account'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () =>
                    _open(context, LoginPage(onSignedIn: onSignedIn)),
                child: const Text('Already have an account? Log In'),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'SnapFix keeps your reports on this device until a barangay '
                  'backend is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10.5, color: AppTheme.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _showGoogleNotice(BuildContext context) => ScaffoldMessenger.of(context)
      .showSnackBar(
        const SnackBar(
          content: Text(
            'Google sign-in is a visual demo; no authentication is performed.',
          ),
        ),
      );
}

/// Shared heading used by the login and sign-up forms.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(color: AppTheme.muted, fontSize: 12.5),
        ),
      ],
    );
  }
}

/// Labelled field used by both auth forms so their spacing stays identical.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 7),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(hintText: hint),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

/// Inline failure message shown when storage rejects a registration or
/// sign-in attempt.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    const danger = Color(0xFFD93B3B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: danger.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: danger.withValues(alpha: .35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 18, color: danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter your email';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 6) return 'Use at least 6 characters';
  return null;
}
