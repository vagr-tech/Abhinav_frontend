// ------------------------------------------------------------
// API SERVICE (SYNCED WITH BACKEND) - FINAL ERROR FREE VERSION
// ------------------------------------------------------------

// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart' as auth;

class ApiService {
  static const String baseUrl = "https://abhinav-backend-z8tm.onrender.com/api";

  // --------------------------------------------------------
  // COMMON HEADERS
  // --------------------------------------------------------
  static Map<String, String> get headers {
    final token = auth.AuthService.token;

    if (token == null) {
      print("❌ API HEADER ERROR: TOKEN IS NULL");
    } else {
      print("✅ API HEADER TOKEN => $token");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // --------------------------------------------------------
  // LOGIN
  // --------------------------------------------------------
  static Future<Map<String, dynamic>> login(
      String phone, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/users/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phone": phone,
        "password": password,
      }),
    );
    return jsonDecode(res.body);
  }

  // --------------------------------------------------------
  // USERS
  // --------------------------------------------------------
  static Future<List<dynamic>> getUsers() async {
    final res = await http.get(
      Uri.parse("$baseUrl/users/"),
      headers: headers,
    );
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body)["users"] ?? [];
  }

  static Future<bool> addUser(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/users/add"),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body)["success"] == true;
  }

  static Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse("$baseUrl/users/$id"),
      headers: headers,
      body: jsonEncode(data),
    );
    return jsonDecode(res.body)["success"] == true;
  }

  static Future<bool> deleteUser(String id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/users/$id"),
      headers: headers,
    );
    return jsonDecode(res.body)["success"] == true;
  }

  // --------------------------------------------------------
  // SHOPS
  // --------------------------------------------------------
  static Future<List<dynamic>> getShops() async {
    final res = await http.get(
      Uri.parse("$baseUrl/shops/list"),
      headers: headers,
    );
    print("SHOP STATUS => ${res.statusCode}");
    print("SHOP RESPONSE => ${res.body}");
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body)["shops"] ?? [];
  }

  static Future<bool> updateShop(Map data) async {
    try {
      final res = await http.put(
        Uri.parse("$baseUrl/shops/update/${data["shop_id"]}"),
        headers: headers,
        body: jsonEncode({
          "shop_name": data["shop_name"],
          "address": data["address"],
          "segment": data["segment"],
          "primaryPhone": data["primaryPhone"] ?? "",
          "secondaryPhone": data["secondaryPhone"] ?? "",
          "gstNumber": data["gstNumber"] ?? "",
        }),
      );

      return jsonDecode(res.body)["success"] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteShop(String id) async {
    final res = await http.delete(
      Uri.parse("$baseUrl/shops/delete/$id"),
      headers: headers,
    );
    return jsonDecode(res.body)["success"] == true;
  }

  // --------------------------------------------------------
  // ASSIGNED SHOPS
  // --------------------------------------------------------
  static Future<List<dynamic>> getAssignedShops(String salesmanId) async {
    final res = await http.get(
      Uri.parse("$baseUrl/assigned/list?salesmanId=$salesmanId"),
      headers: headers,
    );
    print("ASSIGNED STATUS => ${res.statusCode}");
    print("ASSIGNED RAW RESPONSE => ${res.body}");
    if (res.statusCode != 200) return [];
    return jsonDecode(res.body)["assigned"] ?? [];
  }

  // --------------------------------------------------------
  // ASSIGN SHOP (MASTER / MANAGER)
  // --------------------------------------------------------
  static Future<bool> assignShop(
    String shopName,
    String salesmanName,
    String segment,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/assigned/assign"),
      headers: headers,
      body: jsonEncode({
        "shop_name": shopName,
        "salesman_name": salesmanName,
        "segment": segment,
      }),
    );
    print("STATUS: ${res.statusCode}");
    print("BODY: ${res.body}");
    if (res.statusCode != 200) return false;
    final body = jsonDecode(res.body);
    if (body is Map && body["success"] == true) return true;
    return false;
  }

  // --------------------------------------------------------
  // REMOVE ASSIGNED SHOP
  // --------------------------------------------------------
  static Future<bool> removeAssignedShop(
    String salesmanId,
    String sk,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/assigned/remove"),
      headers: headers,
      body: jsonEncode({
        "salesmanId": salesmanId,
        "sk": sk,
      }),
    );
    return jsonDecode(res.body)["success"] == true;
  }

  // --------------------------------------------------------
  // REORDER ASSIGNED SHOPS
  // --------------------------------------------------------
  static Future<bool> reorderAssignedShops(
    String salesmanId,
    List<String> orderSkList,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/assigned/reorder"),
      headers: headers,
      body: jsonEncode({
        "salesmanId": salesmanId,
        "order": orderSkList,
      }),
    );
    return jsonDecode(res.body)["success"] == true;
  }

  // --------------------------------------------------------
  // RESET AND ASSIGN
  // --------------------------------------------------------
  static Future<bool> resetAndAssign(
    String salesmanId,
    String salesmanName,
    List<dynamic> shops,
  ) async {
    final res = await http.post(
      Uri.parse("$baseUrl/assigned/reset-assign"),
      headers: headers,
      body: jsonEncode({
        "salesmanId": salesmanId,
        "salesmanName": salesmanName,
        "shops": shops,
      }),
    );
    print("RESET ASSIGN STATUS => ${res.statusCode}");
    print("RESET ASSIGN BODY => ${res.body}");
    if (res.statusCode != 200) return false;
    return jsonDecode(res.body)["success"] == true;
  }

  // --------------------------------------------------------
  // NEXT SHOP
  // --------------------------------------------------------
  static Future<Map<String, dynamic>> getNextShops() async {
    final res = await http.get(
      Uri.parse("$baseUrl/nextshop/next"),
      headers: headers,
    );
    if (res.statusCode != 200) throw Exception("Failed to load next shops");
    return jsonDecode(res.body);
  }

  // --------------------------------------------------------
  // SALESMAN TODAY
  // --------------------------------------------------------
  static Future<Map<String, dynamic>> getSalesmanToday() async {
    final res = await http.get(
      Uri.parse("$baseUrl/assigned/salesman/today"),
      headers: headers,
    );
    if (res.statusCode != 200) return {};
    return jsonDecode(res.body);
  }

  // --------------------------------------------------------
  // HISTORY LOGS
  // --------------------------------------------------------
  static Future<dynamic> getLogs() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/visits/list"),
        headers: {
          "Authorization": "Bearer ${auth.AuthService.token}",
        },
      );
      print("📜 LOG STATUS => ${res.statusCode}");
      print("📜 LOG BODY => ${res.body}");
      if (res.statusCode != 200) return [];
      return jsonDecode(res.body);
    } catch (e) {
      print("❌ GET LOGS ERROR: $e");
      return [];
    }
  }

  // --------------------------------------------------------
  // MODIFY ASSIGNMENT DATE
  // --------------------------------------------------------
  static Future<bool> modifyAssignmentDate({
    required String salesmanId,
    required String oldSk,
    required String newDate,
  }) async {
    final body = {
      "salesmanId": salesmanId,
      "oldSk": oldSk,
      "newDate": newDate,
    };
    print("MODIFY BODY => $body");
    final res = await http.post(
      Uri.parse("$baseUrl/assigned/modify-date"),
      headers: headers,
      body: jsonEncode(body),
    );
    print("MODIFY STATUS => ${res.statusCode}");
    print("MODIFY RAW => ${res.body}");
    return res.statusCode == 200;
  }

  // --------------------------------------------------------
  // UPDATE SHOP IMAGE
  // --------------------------------------------------------
  static Future<bool> updateShopImage(String id, String base64Image) async {
    final res = await http.put(
      Uri.parse("$baseUrl/shops/update-image/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${auth.AuthService.token}",
      },
      body: jsonEncode({"shopImage": base64Image}),
    );
    return res.statusCode == 200;
  }

  // --------------------------------------------------------
  // DELETE VISIT LOG
  // --------------------------------------------------------
  static Future<bool> deleteVisit(String pk, String sk) async {
    try {
      final response = await http.delete(
        Uri.parse("$baseUrl/visits/delete"),
        headers: headers,
        body: jsonEncode({"pk": pk, "sk": sk}),
      );
      return jsonDecode(response.body)["success"] == true;
    } catch (e) {
      print("❌ DELETE ERROR => $e");
      return false;
    }
  }

  // --------------------------------------------------------
  // DASHBOARD REPORT
  // --------------------------------------------------------
  static Future<Map<String, dynamic>?> getDashboardReport(
      String startDate, String endDate) async {
    try {
      final uri = Uri.https(
        "abhinav-backend-z8tm.onrender.com",
        "/api/history/reports/dashboard",
        {"startDate": startDate, "endDate": endDate},
      );
      print("FINAL URI => $uri");
      final response = await http.get(uri, headers: headers);
      print("STATUS => ${response.statusCode}");
      print("BODY => ${response.body}");
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      return data["success"] == true ? data : null;
    } catch (e) {
      print("Dashboard API Error => $e");
      return null;
    }
  }

  // --------------------------------------------------------
  // ZOHO SALES ORDERS
  // --------------------------------------------------------
  static Future<Map<String, dynamic>> getSalesOrders({
    String? status,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = {
        "page": page.toString(),
        "limit": limit.toString(),
        if (status != null && status != "all") "status": status,
        if (search != null && search.isNotEmpty) "search": search,
      };

      final uri = Uri.parse("$baseUrl/zoho/salesorders")
          .replace(queryParameters: queryParams);

      print("📦 SALES ORDER URL => $uri");

      final res = await http.get(uri, headers: headers);

      print("📦 SALES ORDER STATUS => ${res.statusCode}");
      print("📦 SALES ORDER BODY => ${res.body}");

      if (res.statusCode != 200) return {"success": false, "orders": []};

      return jsonDecode(res.body);
    } catch (e) {
      print("❌ SALES ORDER ERROR => $e");
      return {"success": false, "orders": []};
    }
  }

  // --------------------------------------------------------
  // ZOHO SALES ORDERS SUMMARY
  // --------------------------------------------------------
  static Future<Map<String, dynamic>> getSalesOrdersSummary() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/zoho/salesorders-summary"),
        headers: headers,
      );
      if (res.statusCode != 200) return {};
      return jsonDecode(res.body);
    } catch (e) {
      print("❌ SALES SUMMARY ERROR => $e");
      return {};
    }
  }

  // --------------------------------------------------------
  // ZOHO SHOPS OUTSTANDING
  // --------------------------------------------------------
  static Future<Map<String, dynamic>> getShopsOutstanding() async {
    try {
      final res = await http.get(
        Uri.parse("$baseUrl/zoho/shops-outstanding"),
        headers: headers,
      );

      print("💰 OUTSTANDING STATUS => ${res.statusCode}");
      print("💰 OUTSTANDING BODY => ${res.body}");

      if (res.statusCode != 200) return {"success": false, "shops": []};
      return jsonDecode(res.body);
    } catch (e) {
      print("❌ OUTSTANDING ERROR => $e");
      return {"success": false, "shops": []};
    }
  }

  // --------------------------------------------------------
  // ATTENDANCE REPORT
  // --------------------------------------------------------
  static Future<Map<String, dynamic>?> getAttendanceReport(
      String startDate, String endDate) async {
    try {
      final uri = Uri.https(
        "abhinav-backend-z8tm.onrender.com",
        "/api/attendance/report",
        {
          "startDate": startDate,
          "endDate": endDate,
        },
      );

      print("📅 ATTENDANCE URI => $uri");

      final response = await http.get(uri, headers: headers);

      print("📅 ATTENDANCE STATUS => ${response.statusCode}");
      print("📅 ATTENDANCE BODY => ${response.body}");

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return data["ok"] == true ? data : null;
    } catch (e) {
      print("❌ ATTENDANCE REPORT ERROR => $e");
      return null;
    }
  }

// api_service.dart — ADD THESE METHODS to your existing ApiService class
//
// These 3 methods use your existing _baseUrl, _headers pattern.
// Just paste inside your ApiService class.

// ── POST /live-location (called by LiveLocationService every 1 min) ──
  static Future<void> postLiveLocation({
    required double lat,
    required double lng,
  }) async {
    try {
      await http
          .post(
            Uri.parse("$baseUrl/live-location"),
            headers: headers,
            body: jsonEncode({"lat": lat, "lng": lng}),
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print("📍 postLiveLocation error: $e");
      // Silent fail — LiveLocationService retries next minute
    }
  }

// ── GET /live-location (called by MapRoutePage every 1 min) ──
  static Future<Map<String, dynamic>> getLiveLocations() async {
    final resp = await http
        .get(
          Uri.parse("$baseUrl/live-location"),
          headers: headers,
        )
        .timeout(const Duration(seconds: 10));
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

// ── DELETE /live-location (called on logout) ──
  static Future<void> clearLiveLocation() async {
    try {
      await http
          .delete(
            Uri.parse("$baseUrl/live-location"),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      print("📍 clearLiveLocation error: $e");
    }
  }
}
