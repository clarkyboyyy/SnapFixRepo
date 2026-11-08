import 'package:flutter/material.dart';

import '../data/local_account_store.dart';
import '../data/profile_service.dart';
import '../data/user_profile.dart';
import '../theme/app_theme.dart';
import '../widget/page_header.dart';

typedef ProfileLoader = Future<ProfileResult> Function(String email);

/// Profile tab: the signed-in account, refreshed from the backend.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.account,
    required this.onAuth,
    required this.onEdit,
    required this.onLogout,
    this.loadProfile,
    this.onProfileLoaded,
  });

  final LocalAccount? account;
  final VoidCallback onAuth;
  final VoidCallback onEdit;
  final VoidCallback onLogout;

  /// Replaces the backend lookup, for tests or offline builds.
  final ProfileLoader? loadProfile;

  /// Receives the refreshed account after the backend details are cached.
  final ValueChanged<LocalAccount>? onProfileLoaded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LocalAccountStore _store = LocalAccountStore();
  ProfileService? _service;
  UserProfile? _profile;
  bool _loading = false;
  String? _loadError;

  bool get _signedIn => widget.account != null;

  @override
  void initState() {
    super.initState();
    _loading = _signedIn;
    if (_loading) _fetchProfile();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldEmail = oldWidget.account?.email;
    final email = widget.account?.email;
    if (oldEmail != email) {
      // A different resident signed in: drop the old answer and load again.
      _profile = null;
      _loadError = null;
      _loading = email != null && email.isNotEmpty;
      if (_loading) _fetchProfile();
      return;
    }

    if (_accountEdited(oldWidget.account, widget.account)) {
      // Local edits win over the answer from the last refresh.
      _profile = null;
    }
  }

  @override
  void dispose() {
    _service?.dispose();
    super.dispose();
  }

  static bool _accountEdited(LocalAccount? before, LocalAccount? after) {
    if (identical(before, after)) return false;
    if (before == null || after == null) return before != after;
    return before.name != after.name ||
        before.mobile != after.mobile ||
        before.address != after.address;
  }

  Future<void> _fetchProfile() async {
    final account = widget.account;
    if (account == null) return;

    final email = account.email;
    final loader =
        widget.loadProfile ?? (_service ??= ProfileService()).fetchProfile;
    final result = await loader(email);
    if (!mounted || widget.account?.email != email) return;

    if (!result.isSuccess) {
      setState(() {
        _loading = false;
        _loadError = result.error;
      });
      return;
    }

    final profile = result.profile!;
    final cached = await _store.cacheProfileDetails(
      email: profile.email.isEmpty ? email : profile.email,
      name: profile.fullName,
      mobile: profile.phone,
      address: profile.address,
    );
    if (!mounted || widget.account?.email != email) return;

    setState(() {
      _profile = profile;
      _loading = false;
      _loadError = null;
    });
    if (cached != null) widget.onProfileLoaded?.call(cached);
  }

  Future<void> _retry() async {
    if (!_signedIn || _loading) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    await _fetchProfile();
  }

  String get _displayName {
    final remote = _profile?.fullName.trim() ?? '';
    if (remote.isNotEmpty) return remote;
    final saved = widget.account?.name.trim() ?? '';
    if (saved.isNotEmpty) return saved;
    return widget.account?.email ?? 'Guest user';
  }

  String get _email {
    final remote = _profile?.email.trim() ?? '';
    if (remote.isNotEmpty) return remote;
    final saved = widget.account?.email.trim() ?? '';
    return saved.isEmpty ? 'Not connected' : saved;
  }

  String? get _mobile =>
      _remoteOrCached(_profile?.phone, widget.account?.mobile);

  String? get _address =>
      _remoteOrCached(_profile?.address, widget.account?.address);

  static String? _remoteOrCached(String? remote, String? cached) {
    final fromServer = remote?.trim() ?? '';
    return fromServer.isNotEmpty ? fromServer : cached;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _signedIn ? _retry : () async {},
      color: AppTheme.pink,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          PageHeader(
            title: 'Profile',
            subtitle: !_signedIn
                ? 'Sign in to sync your reports'
                : _loading
                ? 'Refreshing your account details…'
                : 'Your account information',
            action: IconButton(
              onPressed: widget.onAuth,
              tooltip: 'Account settings',
              icon: const Icon(
                Icons.settings_outlined,
                color: AppTheme.pink,
                size: 20,
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(4)),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: AppTheme.pink,
                  backgroundColor: AppTheme.softPink,
                ),
              ),
            ),
          if (_loadError != null)
            _SyncNotice(
              message: _loadError!,
              onRetry: _loading ? null : _retry,
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
                          onPressed: widget.onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Edit profile'),
                        )
                      : FilledButton(
                          onPressed: widget.onAuth,
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
                  value: _signedIn ? _email : 'Not connected',
                ),
                _ContactRow(
                  icon: Icons.phone_outlined,
                  label: 'Mobile number',
                  value: _orMissing(_mobile),
                ),
                _ContactRow(
                  icon: Icons.home_outlined,
                  label: 'Address',
                  value: _orMissing(_address),
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
                onTap: widget.onAuth,
              ),
            ),
        ],
      ),
    );
  }

  /// Placeholder for a field the resident has not filled in yet. Never shows
  /// the stored password digest.
  String _orMissing(String? value) {
    final saved = value?.trim();
    if (saved == null || saved.isEmpty) {
      return _loading ? 'Loading…' : 'Add it in Edit profile';
    }
    return saved;
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

/// Inline notice shown when the profile could not be refreshed.
class _SyncNotice extends StatelessWidget {
  const _SyncNotice({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppTheme.softPink,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_outlined, size: 18, color: AppTheme.pink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, height: 1.35),
            ),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
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
