// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import 'auth_service.dart';

class UserService {
  static const String baseUrl =
      "https://abhinav-backend-z8tm.onrender.com/api/users";

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token ?? ""}",
      };

  // GET USERS
  Future<List<UserModel>> getUsers() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/list"), // ✅ correct
        headers: headers,
      );

      final data = jsonDecode(res.body);
      if (data["success"] != true) return [];

      final List list = data["users"] ?? [];
      return list.map((e) => UserModel.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // ADD USER
  Future<bool> addUser(UserModel user) async {
    try {
      print("🔑 TOKEN: ${AuthService.token}");
      final body = jsonEncode(user.toJson());

      print("📤 SENDING DATA: $body");

      final res = await http.post(
        Uri.parse("$baseUrl/add"),
        headers: headers,
        body: body,
      );

      print("🔵 STATUS CODE: ${res.statusCode}");
      print("🔵 RAW RESPONSE: ${res.body}");

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      print("🔥 FRONTEND ERROR: $e");
      return false;
    }
  }

  // UPDATE USER
  Future<bool> updateUser(UserModel user) async {
    try {
      final url = Uri.parse("$baseUrl/${user.userId}");
      print("UPDATE USER URL => $url");

      final body = {
        "name": user.name,
        "mobile": user.mobile,
        "role": user.role,
        "segment": user.segment,
        "password": user.password,
      };

      print("UPDATE USER BODY => $body");

      final res = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      print("UPDATE USER STATUS => ${res.statusCode}");
      print("UPDATE USER RESPONSE => ${res.body}");

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      print("UPDATE USER ERROR => $e");
      return false;
    }
  }

  // DELETE USER
  Future<bool> deleteUser(String userId) async {
    try {
      final url = Uri.parse("$baseUrl/$userId");
      print("DELETE URL => $url");

      final res = await http.delete(url, headers: headers);

      print("DELETE STATUS => ${res.statusCode}");
      print("DELETE RESPONSE => ${res.body}");

      if (res.statusCode != 200) return false;

      final data = jsonDecode(res.body);
      return data["success"] == true;
    } catch (e) {
      print("DELETE ERROR => $e");
      return false;
    }
  }
}
