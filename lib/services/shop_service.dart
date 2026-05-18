// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shop_model.dart';
import '../services/auth_service.dart';

class ShopService {
  static const String base = "https://abhinav-backend-z8tm.onrender.com/api";

  // ✅ FIXED ROUTE
  String get shopBaseUrl => "$base/shops/list";

  // -----------------------------
  // GET SHOPS
  // -----------------------------
  Future<List<ShopModel>> getShops() async {
    if (AuthService.token == null) {
      await AuthService.init();
    }

    final res = await http.get(
      Uri.parse(shopBaseUrl),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    if (res.statusCode != 200) {
      print("❌ SHOP ERROR: ${res.body}");
      return [];
    }

    final data = jsonDecode(res.body);
    final list = data["shops"] ?? [];
    // SAVE SHOPS IN PREFS
    await AuthService.saveShopsToPrefs(list);
    return list.map<ShopModel>((e) => ShopModel.fromJson(e)).toList();
  }

//------------Approval shop ---------
  Future<bool> approveShop(String id) async {
    final res = await http.put(
      Uri.parse("$base/shops/approve/$id"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    return res.statusCode == 200;
  }

  // -----------------------------
  // UPDATE SHOP
  // -----------------------------
  Future<bool> updateShop(Map data) async {
    final res = await http.put(
      Uri.parse("$base/shops/update/${data["_id"]}"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "shop_name": data["shop_name"],
        "address": data["address"],
        "segment": data["segment"],
      }),
    );

    return res.statusCode == 200;
  }

  // -----------------------------
  // DELETE SHOP
  // -----------------------------
  Future<bool> deleteShop(String shopId) async {
    final res = await http.delete(
      Uri.parse("$base/shops/delete/$shopId"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    return res.statusCode == 200;
  }

  /// Fetch shop details by GST number.
  /// Returns a Map with shop fields on success, null if not found.
  /// Throws an Exception on network/server errors.
  static Future<Map<String, dynamic>?> fetchShopByGst(String gstNumber) async {
    final trimmed = gstNumber.trim();
    if (trimmed.length != 15) return null;

    // ✅ Use full URL directly (avoids static vs instance conflict)
    final url = Uri.parse(
      "https://abhinav-backend-z8tm.onrender.com/api/shops/gst-lookup/$trimmed",
    );

    print("GST URL: $url");
    print("GST TOKEN: ${AuthService.token}");

    final res = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    print("GST STATUS: ${res.statusCode}");
    print("GST BODY: ${res.body}");

    if (res.statusCode == 404) return null;
    if (res.statusCode != 200) {
      throw Exception("GST lookup failed (${res.statusCode})");
    }

    final body = jsonDecode(res.body);
    if (body["success"] == true) {
      return body["data"] as Map<String, dynamic>;
    }

    return null;
  }
}
