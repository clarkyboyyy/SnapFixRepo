import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// The resident's account, saved on this device only.
///
/// This is a local-storage demo with no backend: the credential never leaves
/// the phone, nothing is verified against a real service, and anyone with read
/// access to the app's storage can attempt an offline guess against
/// [LocalAccount.passwordHash]. A production build must move authentication to
/// a server using a slow, per-user hash (argon2id or bcrypt) plus session
/// tokens.
class LocalAccount {
  const LocalAccount({
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
    this.mobile = '',
    this.address = '',
  });

  final String name;
  final String email;

  /// Base64 random salt burned into [passwordHash].
  final String salt;
  final String passwordHash;

  /// Empty until the resident fills them in on the edit-profile form.
  final String mobile;
  final String address;

  LocalAccount copyWith({String? name, String? mobile, String? address}) {
    return LocalAccount(
      name: name ?? this.name,
      email: email,
      salt: salt,
      passwordHash: passwordHash,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
    );
  }

  Map<String, String> toJson() => {
    'name': name,
    'email': email,
    'salt': salt,
    'passwordHash': passwordHash,
    'mobile': mobile,
    'address': address,
  };

  /// Returns null for anything that is missing or malformed rather than
  /// letting one bad write brick start-up.
  static LocalAccount? tryParse(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (decoded is! Map) return null;

    final name = decoded['name'];
    final email = decoded['email'];
    final salt = decoded['salt'];
    final hash = decoded['passwordHash'];
    if (name is! String ||
        email is! String ||
        salt is! String ||
        hash is! String) {
      return null;
    }
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        salt.isEmpty ||
        hash.isEmpty) {
      return null;
    }

    return LocalAccount(
      name: name,
      email: email,
      salt: salt,
      passwordHash: hash,
      mobile: decoded['mobile'] is String ? decoded['mobile'] as String : '',
      address: decoded['address'] is String ? decoded['address'] as String : '',
    );
  }
}

/// Result of a registration or sign-in attempt.
class AuthOutcome {
  const AuthOutcome.signedIn(LocalAccount this.account) : error = null;
  const AuthOutcome.failed(String this.error) : account = null;

  final LocalAccount? account;
  final String? error;

  bool get isSuccess => account != null;
}

/// Reads and writes the one account this demo keeps on the device.
class LocalAccountStore {
  /// Resolved once in `main()` (and in tests) so reads never block a frame on
  /// a platform-channel round trip.
  static SharedPreferences? defaultPrefs;

  LocalAccountStore({SharedPreferences? prefs})
    : _prefs = prefs ?? defaultPrefs;

  final SharedPreferences? _prefs;

  static const _accountKey = 'snapfix.account';
  static const _sessionKey = 'snapfix.sessionEmail';

  static String normalizeEmail(String email) => email.trim().toLowerCase();

  static String _newSalt() {
    final random = Random.secure();
    return base64Encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String digest(String password, String salt) =>
      base64Encode(sha256.convert(utf8.encode('$salt|$password')).bytes);

  Future<SharedPreferences?> _open() async {
    if (_prefs != null) return _prefs;
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      // No storage backend (unsupported platform, disabled disk). Callers
      // treat that as "no account saved".
      return null;
    }
  }

  /// The account registered on this device, if any.
  Future<LocalAccount?> readAccount() async {
    final prefs = await _open();
    final raw = prefs?.getString(_accountKey);
    if (raw == null) return null;

    final account = LocalAccount.tryParse(raw);
    if (account == null) {
      await prefs!.remove(_accountKey);
      await prefs.remove(_sessionKey);
    }
    return account;
  }

  /// The account only while a session for it is still open.
  Future<LocalAccount?> signedInAccount() async {
    final prefs = await _open();
    final sessionEmail = prefs?.getString(_sessionKey);
    if (sessionEmail == null || sessionEmail.isEmpty) return null;

    final account = await readAccount();
    if (account == null || normalizeEmail(account.email) != sessionEmail) {
      return null;
    }
    return account;
  }

  Future<AuthOutcome> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await _open();
    if (prefs == null) {
      return const AuthOutcome.failed(
        'This device blocked local storage, so the account could not be saved.',
      );
    }

    final cleanName = name.trim();
    final cleanEmail = normalizeEmail(email);
    final existing = await readAccount();
    if (existing != null && normalizeEmail(existing.email) == cleanEmail) {
      return AuthOutcome.failed(
        '$cleanEmail is already registered on this device. Log in instead.',
      );
    }

    final salt = _newSalt();
    final account = LocalAccount(
      name: cleanName,
      email: cleanEmail,
      salt: salt,
      passwordHash: digest(password, salt),
    );

    final saved = await _write(prefs, account);
    if (!saved) {
      return const AuthOutcome.failed(
        'Could not save the account on this device. Try again.',
      );
    }

    await prefs.setString(_sessionKey, cleanEmail);
    return AuthOutcome.signedIn(account);
  }

  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    final prefs = await _open();
    if (prefs == null) {
      return const AuthOutcome.failed(
        'This device blocked local storage, so there is no account to check.',
      );
    }

    final account = await readAccount();
    if (account == null) {
      return const AuthOutcome.failed(
        'No account is saved on this device yet. Create one first.',
      );
    }
    if (normalizeEmail(account.email) != normalizeEmail(email)) {
      return AuthOutcome.failed(
        'No SnapFix account for ${normalizeEmail(email)} on this device.',
      );
    }
    if (digest(password, account.salt) != account.passwordHash) {
      return const AuthOutcome.failed(
        'That password does not match the saved account.',
      );
    }

    await prefs.setString(_sessionKey, normalizeEmail(account.email));
    return AuthOutcome.signedIn(account);
  }

  /// Updates the saved profile. Blank input keeps the stored value.
  Future<LocalAccount?> updateProfile({
    required String name,
    String mobile = '',
    String address = '',
  }) async {
    final prefs = await _open();
    final account = await readAccount();
    if (prefs == null || account == null) return null;

    final cleanName = name.trim();
    final cleanMobile = mobile.trim();
    final cleanAddress = address.trim();
    final updated = account.copyWith(
      name: cleanName.isEmpty ? null : cleanName,
      mobile: cleanMobile.isEmpty ? null : cleanMobile,
      address: cleanAddress.isEmpty ? null : cleanAddress,
    );
    if (!await _write(prefs, updated)) return null;

    // Keep the session pointing at the record that is now stored.
    final sessionEmail = prefs.getString(_sessionKey);
    if (sessionEmail == normalizeEmail(account.email)) {
      await prefs.setString(_sessionKey, normalizeEmail(updated.email));
    }
    return updated;
  }

  /// Ends the session but leaves the account registered for the next sign-in.
  Future<void> signOut() async {
    final prefs = await _open();
    if (prefs == null) return;
    await prefs.remove(_sessionKey);
  }

  Future<bool> _write(SharedPreferences prefs, LocalAccount account) async {
    try {
      return await prefs.setString(_accountKey, jsonEncode(account.toJson()));
    } catch (_) {
      return false;
    }
  }
}
