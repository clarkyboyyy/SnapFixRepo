import 'dart:convert';

/// The profile details SnapFix stores for a resident on the backend.
class UserProfile {
  const UserProfile({
    this.id,
    required this.fullName,
    required this.email,
    this.phone = '',
    this.address = '',
  });

  final int? id;
  final String fullName;
  final String email;
  final String phone;
  final String address;

  /// Reads a profile payload, treating missing or non-string values as empty
  /// so one malformed field cannot discard the rest of the profile.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _asInt(json['id']),
      fullName: _asText(json['fullName'] ?? json['full_name']),
      email: _asText(json['email']),
      phone: _asText(json['phone'] ?? json['mobile']),
      address: _asText(json['address']),
    );
  }

  static String _asText(Object? value) => value is String ? value.trim() : '';

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Parses a backend response body, returning null when it does not contain
  /// a profile object.
  static UserProfile? tryParse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

/// Outcome of a profile lookup against the backend.
class ProfileResult {
  const ProfileResult.success(UserProfile this.profile) : error = null;
  const ProfileResult.failure(String this.error) : profile = null;

  final UserProfile? profile;
  final String? error;

  bool get isSuccess => profile != null;
}
