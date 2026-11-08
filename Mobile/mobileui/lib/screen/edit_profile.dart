import 'package:flutter/material.dart';

import '../data/local_account_store.dart';
import '../data/profile_service.dart';
import '../theme/app_theme.dart';
import 'auth_screen.dart';

/// Edit form for the fields SnapFix keeps on the device. The email is the key
/// the login form matches against, so it stays read-only here.
class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.account,
    required this.onSaved,
  });

  final LocalAccount account;
  final void Function(LocalAccount updated) onSaved;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _form = GlobalKey<FormState>();
  final _store = LocalAccountStore();
  final _service = ProfileService();
  late final _name = TextEditingController(text: widget.account.name);
  late final _mobile = TextEditingController(text: widget.account.mobile);
  late final _address = TextEditingController(text: widget.account.address);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _service.dispose();
    _name.dispose();
    _mobile.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    final result = await _service.updateProfile(
      email: widget.account.email,
      name: _name.text,
      phone: _mobile.text,
      address: _address.text,
    );

    if (!mounted) return;
    if (!result.isSuccess) {
      setState(() {
        _busy = false;
        _error = result.error ?? 'Could not save these changes. Try again.';
      });
      return;
    }

    final profile = result.profile!;
    final updated = await _store.cacheProfileDetails(
      email: widget.account.email,
      name: profile.fullName,
      mobile: profile.phone,
      address: profile.address,
      keepBlank: false,
    );

    if (!mounted) return;
    if (updated == null) {
      setState(() {
        _busy = false;
        _error = 'Profile updated, but this device could not store it.';
      });
      return;
    }

    setState(() => _busy = false);
    widget.onSaved(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            const AuthHeading(
              title: 'Your details',
              subtitle:
                  'The barangay uses these to reach you about a report you '
                  'filed.',
            ),
            const SizedBox(height: 26),
            AuthField(
              label: 'Full Name',
              controller: _name,
              hint: 'e.g. Zyra Malik',
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter your name' : null,
            ),
            _ReadOnlyField(label: 'Email Address', value: widget.account.email),
            AuthField(
              label: 'Mobile Number (optional)',
              controller: _mobile,
              hint: 'e.g. 0917 123 4567',
              keyboardType: TextInputType.phone,
              validator: validateMobile,
            ),
            AuthField(
              label: 'Address (optional)',
              controller: _address,
              hint: 'e.g. 12 Rizal Avenue, Purok 3',
              textCapitalization: TextCapitalization.words,
            ),
            if (_error != null) ...[
              AuthErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save changes'),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Saved to your account. Leave a field blank to clear it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: AppTheme.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Field styled like the auth inputs but not editable.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.lock_outline, size: 16, color: AppTheme.muted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
