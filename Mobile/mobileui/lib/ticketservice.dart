import 'package:http/http.dart' as http;

import 'dart:convert';

class TicketService {
  static Future<void> submitTicket(
    String id,
    String title,
    String location,
    String description,
  ) async {
    var url = Uri.parse('http://localhost:5141/api/tickets');

    var ticketData = {
      "id": id,
      "title": title,
      "location": location,
      "description": description,
      "dateSubmitted": DateTime.now().toUtc().toIso8601String(),
      "status": "Pending",
      "priority": "High",
    };

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(ticketData),
    );

    // If it's NOT a success code (200 or 201), throw an error!
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Backend error: ${response.body}");
    }
  }

  static Future<void> sendMessage(String ticketId, String text) async {
    var url = Uri.parse('http://localhost:5141/api/messages');
    
    var messageData = {
      "ticketId": ticketId,
      "message": text,
      "senderType": "citizen",
      "dateSent": DateTime.now().toUtc().toIso8601String()
    };

    var response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(messageData), 
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send message. Status: ${response.statusCode}');
    }
  }

  static Future<List<dynamic>> fetchTickets() async {
    var url = Uri.parse('http://localhost:5141/api/tickets');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load tickets');
    }
  }
}
