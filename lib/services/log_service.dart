import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class LogService {
  static const String baseUrl =
      "https://abhinav-backend-z8tm.onrender.com/api/visits";

  // ---------------------------
  // UPLOAD PHOTO (BASE64)
  // ---------------------------
  Future<String?> uploadPhoto(String base64, String name) async {
    // if you already upload elsewhere, keep it
    return "uploaded_url_dummy"; // keep simple
  }

  // ---------------------------
  // SAVE VISIT
  // ---------------------------
  Future<bool> saveVisit(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/save"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );

    final body = jsonDecode(res.body);
    return body["success"] == true;
  }

  // ---------------------------
  // GET VISITS BY STATUS
  // ---------------------------
  Future<List<dynamic>> getVisits(String status) async {
    final res = await http.get(
      Uri.parse("$baseUrl/status/$status"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    final body = jsonDecode(res.body);
    return body["visits"] ?? [];
  }
}
