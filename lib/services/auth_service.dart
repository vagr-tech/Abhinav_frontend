// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // ✔ Backend base URL
  static const String baseApi =
      "https://abhinav-backend-z8tm.onrender.com/api/users";

  static String? token;
  static Map<String, dynamic>? currentUser;

  // ---------------------------------------------------------
  // INIT → LOAD TOKEN & USER AT APP START
  // ---------------------------------------------------------
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    token = prefs.getString("token");

    final savedUser = prefs.getString("user");
    if (savedUser != null) {
      currentUser = jsonDecode(savedUser);
    }
  }

  static Future<void> saveToken(String t) async {
    token = t;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", t);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  static Future<void> saveShopsToPrefs(List shops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("shops_cache", jsonEncode(shops));
  }

  static Future<List> getShopsFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString("shops_cache");
    if (raw == null) return [];
    return jsonDecode(raw) as List;
  }

  // ---------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    try {
      final url = Uri.parse("$baseApi/login");

      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phone": phone.trim(),
          "password": password.trim(),
        }),
      );

      final data = jsonDecode(res.body);
      print("LOGIN FULL RESPONSE: $data");
      print("LOGIN USER: ${data["user"]}");
      print("LOGIN ROLE: ${data["user"]?["role"]}");
      print("LOGIN SEGMENT: ${data["user"]?["segment"]}");
      print("LOGIN TOKEN: ${data["token"]}");

      // ❌ Login failed
      if (data["success"] != true) {
        return data;
      }

      // -----------------------------------------------------
      // SAVE TOKEN + USER (IMPORTANT)
      // -----------------------------------------------------
      final prefs = await SharedPreferences.getInstance();

      token = data["token"];
      currentUser = data["user"];

      // 🔥 MUST AWAIT
      await prefs.setString("token", token!);
      await prefs.setString("user", jsonEncode(currentUser));

      return data;
    } catch (e) {
      return {
        "success": false,
        "message": "Network error",
        "error": e.toString(),
      };
    }
  }

  // ---------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("token");
    await prefs.remove("user");

    token = null;
    currentUser = null;
  }

  // ---------------------------------------------------------
  // COMMON AUTH HEADER
  // ---------------------------------------------------------
  static Map<String, String> get authHeader => {
        "Content-Type": "application/json",
        if (token != null) "Authorization": "Bearer $token",
      };

  static Future<Map<String, dynamic>> registerMaster(
    String companyName,
    String name,
    String mobile,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse("$baseApi/register-master"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "companyName": companyName,
          "name": name,
          "mobile": mobile,
          "password": password,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
