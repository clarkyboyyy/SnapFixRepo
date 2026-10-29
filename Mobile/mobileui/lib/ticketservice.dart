import 'package:http/http.dart' as http;
import 'dart:convert';

class TicketService {
  static Future<void> submitTicket(String title, String location, String description) async {
    var url = Uri.parse('http://localhost:5141/api/tickets'); 
    
    var ticketData = {
      "id": "SF-${DateTime.now().millisecondsSinceEpoch}", 
      "title": title,
      "location": location,
      "description": description,
      "dateSubmitted": DateTime.now().toUtc().toIso8601String(),
      "status": "Pending",
      "priority": "High"
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