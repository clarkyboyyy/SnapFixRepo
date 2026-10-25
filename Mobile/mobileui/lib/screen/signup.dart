import 'package:flutter/material.dart';

import '../data/local_account_store.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// New resident: name, email and a confirmed password.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.onSignedIn});

  final void Function(String email, String? name) onSignedIn;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _form = GlobalKey<FormState>();
  final _store = LocalAccountStore();
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

    final outcome = await _store.register(
      name: _name.text,
      email: _email.text,
      password: _password.text,
    );

    if (!mounted) return;
    if (!outcome.isSuccess) {
      setState(() {
        _busy = false;
        _error = outcome.error;
      });
      return;
    }

    final account = outcome.account!;
    widget.onSignedIn(account.email, account.name);
    setState(() => _busy = false);
    Navigator.of(context).popUntil((route) => route.isFirst);
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
                'Demo only: this profile stays on your device.',
                style: TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
