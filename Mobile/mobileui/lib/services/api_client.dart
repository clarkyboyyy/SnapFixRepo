import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../apiconfig.dart';

/// A backend failure the UI can show the resident directly.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// The request never reached the backend (offline, wrong host, DNS).
  bool get isOffline => statusCode == null;

  @override
  String toString() => message;
}

/// Thin JSON wrapper over the SnapFix API so every screen talks to one place.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? testClient ?? http.Client();

  final http.Client _client;

  /// Widget tests put an in-memory backend here, the same way they mock
  /// SharedPreferences, so no screen ever opens a real socket. `flutter_test`
  /// refuses outgoing HTTP outright, so this is the only supported seam.
  static http.Client? testClient;

  static const Duration _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = ApiConfig.baseUrl.endsWith('/')
        ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
        : ApiConfig.baseUrl;
    return Uri.parse('$base$path').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final decoded = await _send(() => _client.get(_uri(path, query)));
    return _asMap(decoded, path);
  }

  /// Endpoints that answer with a bare array, such as the ticket list.
  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
  }) async {
    final decoded = await _send(() => _client.get(_uri(path, query)));
    if (decoded is List) return decoded;
    throw ApiException('Unexpected reply from $path.');
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final decoded = await _send(
      () => _client.post(
        _uri(path),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      ),
    );
    return _asMap(decoded, path);
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    final decoded = await _send(
      () => _client.put(
        _uri(path),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      ),
    );
    return _asMap(decoded, path);
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    final decoded = await _send(() => _client.delete(_uri(path)));
    return _asMap(decoded, path);
  }

  /// Uploads one image and returns the public URL the backend stored it at.
  Future<String> uploadPhoto({required File photo, String? ticketId}) async {
    final request = http.MultipartRequest('POST', _uri('/api/tickets/photo'));
    if (ticketId != null && ticketId.isNotEmpty) {
      request.fields['ticketId'] = ticketId;
    }
    request.files.add(await http.MultipartFile.fromPath('photo', photo.path));

    try {
      // Sent through _client so a mocked backend sees uploads too.
      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final data = _asMap(_decode(response), '/api/tickets/photo');
      final url = data['url'];
      if (url is! String || url.isEmpty) {
        throw const ApiException('The backend did not return a photo URL.');
      }
      return url;
    } on SocketException {
      throw ApiException(_offlineMessage);
    } on TimeoutException {
      throw ApiException(_timeoutMessage);
    } on http.ClientException {
      throw ApiException(_offlineMessage);
    }
  }

  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  static const String _offlineMessage =
      'Cannot reach the SnapFix server. Check your connection and try again.';
  static const String _timeoutMessage =
      'The server took too long to answer. Please try again.';

  Future<Object?> _send(Future<http.Response> Function() request) async {
    try {
      return _decode(await request().timeout(_timeout));
    } on ApiException {
      rethrow;
    } on SocketException {
      throw ApiException(_offlineMessage);
    } on TimeoutException {
      throw ApiException(_timeoutMessage);
    } on http.ClientException {
      throw ApiException(_offlineMessage);
    }
  }

  Map<String, dynamic> _asMap(Object? decoded, String path) {
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Unexpected reply from $path.');
  }

  Object? _decode(http.Response response) {
    Object? decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final serverMessage = decoded is Map
        ? (decoded['message'] ?? decoded['detail'] ?? decoded['error'])
        : null;
    throw ApiException(
      serverMessage is String && serverMessage.isNotEmpty
          ? serverMessage
          : 'The server rejected the request '
                '(status ${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  void close() => _client.close();
}
