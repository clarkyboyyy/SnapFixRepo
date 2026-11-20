import 'dart:convert';

import 'package:http/http.dart' as http;

import '../apiconfig.dart';

class TicketService {
  static String get _baseUrl => ApiConfig.baseUrl;

  //dito mafetch mga ticket na na-submit ng user ibat ibang email na
  static Future<void> submitTicket(
    String id,
    String title,
    String location,
    String description, {
    String? userEmail,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/tickets'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "id": id,
        "title": title,
        "location": location,
        "description": description,
        "dateSubmitted": DateTime.now().toUtc().toIso8601String(),
        "status": "Submitted",
        "priority": "High",
        if (userEmail != null && userEmail.trim().isNotEmpty)
          "userEmail": userEmail.trim().toLowerCase(),
      }),
    );

    // If it's NOT a success code (200 or 201), throw an error!
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Backend error: ${response.body}");
    }
  }

  /// The latest state of one ticket, including progress and assignment.
  static Future<Map<String, dynamic>> fetchTicket(String ticketId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/tickets/${Uri.encodeComponent(ticketId)}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load ticket ${response.statusCode}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  /// Admin status/progress history for a ticket, newest first.
  static Future<List<dynamic>> fetchUpdates(String ticketId) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/tickets/${Uri.encodeComponent(ticketId)}/updates',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load ticket history ${response.statusCode}');
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<List<dynamic>> fetchMessages(String ticketId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/messages/${Uri.encodeComponent(ticketId)}'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load messages ${response.statusCode}');
    }

    return jsonDecode(response.body) as List<dynamic>;
  }

  static Future<void> sendMessage(String ticketId, String text) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/messages'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "ticketId": ticketId,
        "message": text,
        "senderType": "citizen",
        "dateSent": DateTime.now().toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message. Status: ${response.statusCode}');
    }
  }

  /// Reports filed by [userEmail]; without it the backend returns everything
  /// (used by the web admin dashboard, not the mobile app).
  static Future<List<dynamic>> fetchTickets({String? userEmail}) async {
    final uri = Uri.parse('$_baseUrl/api/tickets').replace(
      queryParameters: userEmail == null || userEmail.trim().isEmpty
          ? null
          : {'email': userEmail.trim().toLowerCase()},
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load tickets');
    }
  }
}
