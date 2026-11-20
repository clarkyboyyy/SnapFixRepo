// ignore_for_file: file_names
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apiconfig.dart';
import '../models/issuecategory.dart';

/// Watches the signed-in resident's tickets for new admin updates and reports
/// the ones posted while the app is running.
///
/// In-app only: the timer lives in this object, which the shell disposes with
/// itself, so nothing runs while the app is closed.
class AppWebNotif {
  AppWebNotif({
    required this.owner,
    required this.ticketIds,
    required this.onNewUpdate,
    http.Client? client,
    String? baseUrl,
    this.interval = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  /// Email of the resident currently signed in, or null when signed out.
  final String? Function() owner;

  /// Tickets that belong to that resident right now.
  final List<String> Function() ticketIds;

  /// Called for each update that appeared after the previous check.
  final void Function(String ticketId, ReportUpdate update) onNewUpdate;

  final Duration interval;
  final http.Client _client;
  final String _baseUrl;

  final Map<String, int> _seen = {};
  String? _ownerKey;
  Timer? _timer;
  bool _busy = false;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => checkNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stop();
    _client.close();
  }

  /// Polls once. The first visit to a ticket only records where it stands so
  /// its older history is not replayed as notifications.
  Future<void> checkNow() async {
    if (_busy) return;

    final who = (owner() ?? '').trim().toLowerCase();
    if (who.isEmpty) {
      _seen.clear();
      _ownerKey = null;
      return;
    }
    if (who != _ownerKey) {
      // Another account: its history has never been shown here, so start clean.
      _ownerKey = who;
      _seen.clear();
    }

    final ids = ticketIds();
    if (ids.isEmpty) return;

    _busy = true;
    try {
      for (final id in ids) {
        final latest = await _latestUpdate(id);
        if (latest == null) continue;

        final previous = _seen[id];
        _seen[id] = latest.id;
        // previous == null is the ticket's first look here: its current
        // history is the baseline, not news. A ticket with an empty history
        // records id 0 so its first real update still pops.
        if (previous != null && latest.id > previous) {
          final newest = latest.update;
          if (newest != null) onNewUpdate(id, newest);
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<({int id, ReportUpdate? update})?> _latestUpdate(
    String ticketId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$_baseUrl/api/tickets/${Uri.encodeComponent(ticketId)}/updates',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! List) return null;

      var newestId = 0;
      ReportUpdate? newest;
      for (final item in decoded) {
        if (item is! Map) continue;
        final update = ReportUpdate.fromJson(Map<String, dynamic>.from(item));
        if (newest == null || update.id >= newestId) {
          newest = update;
          newestId = update.id;
        }
      }
      return (id: newestId, update: newest);
    } on Exception {
      // Backend unreachable or a malformed row; try again on the next tick.
      return null;
    }
  }

  /// One-line description of an admin update, used in the pop-up.
  static String describe(ReportUpdate update) {
    final note = update.note?.trim() ?? '';
    if (note.isNotEmpty) return 'Admin note: $note';

    final status = update.status?.trim() ?? '';
    if (status.isEmpty) return 'Your report was updated.';
    if (update.progress > 0 && status != ReportStatus.resolved) {
      return 'Status changed to $status (${update.progress}%).';
    }
    return 'Status changed to $status.';
  }
}
