import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../apiconfig.dart';

/// One GPS fix taken from the device.
class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  /// Shown under the form field, e.g. `14.599512, 120.984222`.
  String get label =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// A location problem the form can show the resident directly.
class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads the device GPS so a report can carry latitude/longitude.
///
/// Every failure is reported as a [LocationException] with a message the form
/// can display; callers never have to know about plugin-specific exceptions.
class LocationService {
  LocationService._();

  static String get _baseUrl => ApiConfig.baseUrl;

  /// Turns a fix into a readable place name through the SnapFix API.
  ///
  /// Returns null when the lookup fails (backend offline, unknown address), so
  /// callers can fall back to the raw coordinates.
  static Future<String?> describe(DeviceLocation location) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/locations/reverse').replace(
        queryParameters: {
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final body = jsonDecode(response.body);
      if (body is! Map) return null;

      final name = body['name']?.toString().trim();
      return name == null || name.isEmpty ? null : name;
    } on Exception {
      return null;
    }
  }

  /// Returns one high-accuracy fix, asking for permission when needed.
  ///
  /// Call it from a tap handler or a submit action, never during build.
  static Future<DeviceLocation> currentLocation() async {
    try {
      return await _readDeviceLocation();
    } on LocationException {
      rethrow;
    } on Exception {
      // Missing plugin, blocked by the OS, or an unsupported device.
      throw const LocationException(
        'Location is not available on this device right now.',
      );
    }
  }

  static Future<DeviceLocation> _readDeviceLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      throw const LocationException(
        'Turn on your device location (GPS) and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationException(
        'Location permission denied. Allow it to attach GPS coordinates.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location is blocked for SnapFix. Enable it in Settings > Apps > '
        'SnapFix > Permissions.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      // Indoors the fix can take longer than the resident wants to wait; the
      // last known position still gives the crew a usable pin.
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        throw const LocationException(
          'Could not get a GPS fix. Move somewhere with a clearer view and '
          'try again.',
        );
      }
      return DeviceLocation(
        latitude: last.latitude,
        longitude: last.longitude,
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        'Turn on your device location (GPS) and try again.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        'Location permission denied. Allow it to attach GPS coordinates.',
      );
    }
  }
}
