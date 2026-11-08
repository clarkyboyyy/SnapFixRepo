import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads the message the backend attached to an error response, falling back
/// to [fallback] when the body has none.
String apiMessage(http.Response response, {required String fallback}) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }

      final errors = decoded['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty && value.first is String) {
            final first = (value.first as String).trim();
            if (first.isNotEmpty) return first;
          }
        }
      }

      final title = decoded['title'];
      if (title is String && title.trim().isNotEmpty) {
        return title.trim();
      }
    }
  } on FormatException {
    // The body was not JSON; use the caller's fallback.
  }
  return fallback;
}
