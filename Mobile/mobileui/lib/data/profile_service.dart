import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apiconfig.dart';
import 'api_message.dart';
import 'user_profile.dart';

/// Reads and updates resident profiles on the SnapFix backend.
class ProfileService {
  ProfileService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 10);

  /// Loads the profile stored for [email]. Failures are reported as a
  /// [ProfileResult] instead of throwing, so the screen can fall back to the
  /// copy cached on this device.
  Future<ProfileResult> fetchProfile(String email) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      return const ProfileResult.failure(
        'No email is available for this account.',
      );
    }

    final uri = Uri.parse('$_baseUrl/api/auth/profile')
        .replace(queryParameters: {'email': cleanEmail});

    return _send(() => _client.get(uri));
  }

  /// Saves the editable profile fields and returns what the backend stored.
  Future<ProfileResult> updateProfile({
    required String email,
    required String name,
    String phone = '',
    String address = '',
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      return const ProfileResult.failure(
        'No email is available for this account.',
      );
    }

    final uri = Uri.parse('$_baseUrl/api/auth/profile');
    return _send(
      () => _client.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': cleanEmail,
          'fullName': name.trim(),
          'phone': phone.trim(),
          'address': address.trim(),
        }),
      ),
    );
  }

  Future<ProfileResult> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);

      if (response.statusCode != 200) {
        return ProfileResult.failure(
          apiMessage(
            response,
            fallback: 'The server returned HTTP ${response.statusCode}.',
          ),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return const ProfileResult.failure(
          'The server returned an unexpected profile.',
        );
      }
      return ProfileResult.success(UserProfile.fromJson(decoded));
    } on TimeoutException {
      return const ProfileResult.failure(
        'The server took too long to respond.',
      );
    } on http.ClientException {
      return const ProfileResult.failure(
        'Cannot reach the server. Is the backend running?',
      );
    } on FormatException {
      return const ProfileResult.failure(
        'The server returned an unreadable response.',
      );
    } catch (_) {
      return const ProfileResult.failure(
        'Could not reach your profile right now.',
      );
    }
  }

  void dispose() => _client.close();
}
