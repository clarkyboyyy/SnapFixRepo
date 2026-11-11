import 'dart:async';

import '../data/local_account_store.dart';
import '../models/user_profile.dart';
import 'api_client.dart';

/// Everything the app does against `api/auth`: register, sign in, read the
/// saved profile, and end the session.
///
/// A successful call is mirrored into [LocalAccountStore] so the resident stays
/// signed in across app restarts even while offline.
class AuthService {
  AuthService({ApiClient? api, LocalAccountStore? accounts})
    : _api = api ?? ApiClient(),
      _accounts = accounts ?? LocalAccountStore();

  final ApiClient _api;
  final LocalAccountStore _accounts;

  static final AuthService instance = AuthService();

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    final response = await _api.postJson('/api/auth/register', {
      'fullName': name.trim(),
      'email': email.trim(),
      'password': password,
      if (phone.trim().isNotEmpty) 'phone': phone.trim(),
    });

    final profile =
        _profileFrom(response) ??
        UserProfile(email: email.trim(), fullName: name.trim(), phone: phone);

    await _accounts.saveSignedIn(
      name: profile.displayName,
      email: profile.email,
      mobile: profile.phone ?? '',
      token: _tokenFrom(response),
    );

    return profile;
  }

  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.postJson('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });

    final profile = _profileFrom(response) ?? UserProfile(email: email.trim());

    await _accounts.saveSignedIn(
      name: profile.displayName,
      email: profile.email,
      mobile: profile.phone ?? '',
      token: _tokenFrom(response),
    );

    return profile;
  }

  /// The saved profile for [email], or null when the backend has no record.
  Future<UserProfile?> fetchProfile(String email) async {
    try {
      final response = await _api.getJson(
        '/api/auth/profile',
        query: {'email': email},
      );
      return UserProfile.tryParse(response);
    } on ApiException catch (error) {
      if (error.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Pushes Edit Profile changes so the Profile screen reads the same values
  /// back from the server.
  Future<UserProfile?> updateProfile({
    required String email,
    required String fullName,
    String? phone,
  }) async {
    final response = await _api.putJson('/api/auth/profile', {
      'email': email,
      'fullName': fullName.trim(),
      if (phone != null) 'phone': phone.trim(),
    });
    return _profileFrom(response);
  }

  /// Clears the session and the stored token on this device.
  Future<void> signOut() => _accounts.signOut();

  Future<LocalAccount?> signedInAccount() => _accounts.signedInAccount();

  /// The account this device last used, even while its session is closed, so
  /// the Profile screen can still show a name before sign-in.
  Future<LocalAccount?> storedAccount() => _accounts.readAccount();

  UserProfile? _profileFrom(Map<String, dynamic> response) =>
      UserProfile.tryParse(response['profile']) ??
      UserProfile.tryParse(response);

  String? _tokenFrom(Map<String, dynamic> response) {
    final token = response['token'];
    return token is String && token.isNotEmpty ? token : null;
  }
}
