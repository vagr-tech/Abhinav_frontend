import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DashboardService {
  static const baseUrl =
      "https://abhinav-backend-z8tm.onrender.com/api/dashboard";

  Future getMasterDashboard() async {
    final res = await http.get(
      Uri.parse("$baseUrl/master"),
      headers: {"Authorization": "Bearer ${AuthService.token}"},
    );
    return jsonDecode(res.body);
  }

  Future getManagerDashboard(String segment) async {
    final res = await http.get(
      Uri.parse("$baseUrl/manager/$segment"),
      headers: {"Authorization": "Bearer ${AuthService.token}"},
    );
    return jsonDecode(res.body);
  }

  Future getSalesmanDashboard(String id) async {
    final res = await http.get(
      Uri.parse("$baseUrl/salesman/$id"),
      headers: {"Authorization": "Bearer ${AuthService.token}"},
    );
    return jsonDecode(res.body);
  }
}
