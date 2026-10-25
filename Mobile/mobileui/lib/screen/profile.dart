import 'package:flutter/material.dart';

import '../data/local_account_store.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';

/// Profile tab: the account saved on this device, and the way to edit it.
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.account,
    required this.onAuth,
    required this.onEdit,
    required this.onLogout,
  });

  final LocalAccount? account;
  final VoidCallback onAuth;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  bool get _signedIn => account != null;

  String get _displayName {
    final saved = account?.name.trim();
    if (saved != null && saved.isNotEmpty) return saved;
    return account?.email ?? 'Guest user';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        PageHeader(
          title: 'Profile',
          subtitle: _signedIn
              ? 'Your account information'
              : 'Sign in to sync your reports',
          action: IconButton(
            onPressed: onAuth,
            tooltip: 'Account settings',
            icon: const Icon(
              Icons.settings_outlined,
              color: AppTheme.pink,
              size: 20,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 33,
                backgroundColor: AppTheme.softPink,
                child: _signedIn
                    ? Text(
                        _initials(),
                        style: const TextStyle(
                          color: AppTheme.pink,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline,
                        color: AppTheme.pink,
                        size: 31,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                _displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _signedIn ? 'Signed in on this device' : 'Not signed in',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.muted),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: _signedIn
                    ? OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 17),
                        label: const Text('Edit profile'),
                      )
                    : FilledButton(
                        onPressed: onAuth,
                        child: const Text('Connect Account / Log In'),
                      ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SectionLabel('CONTACT INFORMATION'),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            children: [
              _ContactRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: account?.email ?? 'Not connected',
              ),
              _ContactRow(
                icon: Icons.phone_outlined,
                label: 'Mobile number',
                value: _orMissing(account?.mobile),
              ),
              _ContactRow(
                icon: Icons.home_outlined,
                label: 'Address',
                value: _orMissing(account?.address),
                isLast: true,
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.softPink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              Icon(Icons.account_balance_outlined, color: AppTheme.pink),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Barangay San Isidro',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Reports go to the barangay hall that covers your area.',
                      style: TextStyle(fontSize: 11, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_signedIn)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.pink),
              title: const Text(
                'Log out',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: onLogout,
            ),
          ),
      ],
    );
  }

  /// Placeholder for a field the resident has not filled in yet. Never shows
  /// the stored password digest.
  static String _orMissing(String? value) {
    final saved = value?.trim();
    return (saved == null || saved.isEmpty) ? 'Add it in Edit profile' : saved;
  }

  String _initials() {
    final parts = _displayName.split(RegExp(r'[\s@._-]+'))
      ..removeWhere((p) => p.isEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.pink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
      ],
    );
  }
}
