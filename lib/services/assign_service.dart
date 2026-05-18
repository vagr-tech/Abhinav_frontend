// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AssignService {
  static const String baseUrl =
      "https://abhinav-backend-z8tm.onrender.com/api/assign";

  /// ------------------------------------------------
  /// ASSIGN SHOPS  (OLD BULK ASSIGN - LEAVE AS IS)
  /// ------------------------------------------------
  Future<bool> assignShops({
    required dynamic userId,
    required List<String> shopIds,
    required double lat,
    required double lng,
  }) async {
    final body = {
      "salesmanId": userId.toString(),
      "shops": shopIds,
      "salesman_lat": lat,
      "salesman_lng": lng,
    };

    final res = await http.post(
      Uri.parse("$baseUrl/assignShops"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      print("❌ Server Error ${res.statusCode}");
      return false;
    }

    final data = jsonDecode(res.body);
    return data["status"] == "success";
  }

  /// -----------------------------
  /// DELETE ASSIGNED SHOP (FIXED)
  /// -----------------------------
  Future<bool> deleteAssignedShop({
    required String shopId,
    required String salesmanId,
  }) async {
    final url = Uri.parse("$baseUrl/remove");

    final body = {
      "shopId": shopId,
      "salesmanId": salesmanId,
    };

    final res = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("DELETE ASSIGN RESPONSE: ${res.body}");

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body);
    return data["status"] == "success";
  }

  /// -----------------------------
  /// REASSIGN SHOP (FIXED)
  /// -----------------------------
  Future<bool> reassignShop({
    required String oldSalesmanId,
    required String newSalesmanId,
    required String shopId,
    required String assignedBy,
  }) async {
    final url = Uri.parse("$baseUrl/reassign");

    final body = {
      "oldSalesmanId": oldSalesmanId,
      "newSalesmanId": newSalesmanId,
      "shopId": shopId,
      "assignedBy": assignedBy,
    };

    final res = await http.post(
      url,
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    print("REASSIGN RESPONSE: ${res.body}");

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body);
    return data["status"] == "success";
  }

  /// -----------------------------
  /// NEXT SHOPS (NEARBY, SORTED)
  /// -----------------------------
  Future<List<dynamic>> getNextShops(
    String userId,
    double lat,
    double lng,
  ) async {
    final url = Uri.parse("$baseUrl/next/$userId?lat=$lat&lng=$lng");

    print("👉 CALLING NEXT SHOPS: $url");

    final res = await http.get(
      url,
      headers: {"Authorization": "Bearer ${AuthService.token}"},
    );

    print("👉 NEXT SHOPS RESPONSE: ${res.statusCode} ${res.body}");

    if (res.statusCode != 200) {
      print("❌ Next Shop Error ${res.statusCode}");
      return [];
    }

    final data = jsonDecode(res.body);
    if (data["success"] != true) {
      print("❌ Next Shop API success=false");
      return [];
    }

    final shops = data["shops"] ?? [];

    // Map to structure compatible with ShopModel.fromJson
    return shops.map((s) {
      return {
        "shop_id": s["shop_id"],
        "shop_name": s["shop_name"] ?? "",
        "address": s["address"] ?? "",
        "lat": _safeDouble(s["lat"]),
        "lng": _safeDouble(s["lng"]),

        // below fields are optional – ShopModel expects them
        "segment": s["segment"] ?? "",
        "created_by": s["created_by"] ?? "",
        "created_at": s["created_at"] ?? "",
        "status": s["status"] ?? "",
      };
    }).toList();
  }

  double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();

    String s = v.toString().trim();
    if (s.isEmpty || s.toLowerCase() == "null") return 0.0;

    return double.tryParse(s) ?? 0.0;
  }
}
