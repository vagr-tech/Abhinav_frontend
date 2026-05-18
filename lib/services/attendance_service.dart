// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AttendanceService {
  static const String _base =
      "https://abhinav-backend-z8tm.onrender.com/api/attendance";

  // ---------------- CHECK-IN ----------------
  Future<Map<String, dynamic>> checkIn({
    required double lat,
    required double lng,
  }) async {
    final res = await http.post(
      Uri.parse("$_base/check-in"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token}",
      },
      body: jsonEncode({"lat": lat, "lng": lng}),
    );

    print("✅ CHECK-IN STATUS => ${res.statusCode}");
    print("✅ CHECK-IN BODY   => ${res.body}");

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------- CHECK-OUT ----------------
  Future<Map<String, dynamic>> checkOut({
    required double lat,
    required double lng,
  }) async {
    final res = await http.post(
      Uri.parse("$_base/check-out"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token}",
      },
      body: jsonEncode({"lat": lat, "lng": lng}),
    );

    print("🔴 CHECK-OUT STATUS => ${res.statusCode}");
    print("🔴 CHECK-OUT BODY   => ${res.body}");

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------------- TODAY STATUS ----------------
  Future<Map<String, dynamic>> todayStatus() async {
    final res = await http.get(
      Uri.parse("$_base/today"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    print("📋 TODAY STATUS => ${res.statusCode}");
    print("📋 TODAY BODY   => ${res.body}");

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
