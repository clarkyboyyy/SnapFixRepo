/// The account record the backend keeps for the signed-in resident.
class UserProfile {
  const UserProfile({required this.email, this.id, this.fullName, this.phone});

  final int? id;
  final String email;
  final String? fullName;
  final String? phone;

  bool get hasName => (fullName ?? '').trim().isNotEmpty;

  /// Name when the resident gave one, otherwise the email keeps the UI honest.
  String get displayName => hasName ? fullName!.trim() : email;

  static UserProfile? tryParse(Object? json) {
    if (json is! Map) return null;

    final email = _string(json, ['email', 'Email', 'username', 'Username']);
    if (email == null || email.isEmpty) return null;

    final rawId = json['id'] ?? json['Id'];

    return UserProfile(
      id: rawId is int ? rawId : int.tryParse('${rawId ?? ''}'),
      email: email,
      fullName: _string(json, ['fullName', 'FullName', 'name', 'Name']),
      phone: _string(json, ['phone', 'Phone', 'mobile', 'Mobile']),
    );
  }

  static String? _string(Map json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
