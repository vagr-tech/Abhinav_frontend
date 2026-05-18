// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class PendingShopService {
  static const String base = "https://abhinav-backend-z8tm.onrender.com/api";

  Map<String, String> get headers => {
        "Content-Type": "application/json",
        if (AuthService.token != null)
          "Authorization": "Bearer ${AuthService.token}",
      };

  // -------------------------------------------------------
  // GET PENDING SHOPS (MASTER / MANAGER)
  // -------------------------------------------------------
  Future<List<dynamic>> getPendingShops() async {
    final url = Uri.parse("$base/pending/list");

    final res = await http.get(url, headers: headers);
    print("RAW RESPONSE:");
    print(res.body); // 🔥 VERY IMPORTANT

    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    print("DECODED:");
    print(data);
    final List shops = data["shops"] ?? [];

    // ✅ ONLY PENDING
    return shops;
  }

  // -------------------------------------------------------
  // APPROVE SHOP
  // -------------------------------------------------------
  Future<bool> approveShop(String shopId) async {
    final url = Uri.parse("$base/shops/approve/$shopId");

    final res = await http.put(url, headers: headers);

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body);
    return data["success"] == true;
  }

  // -------------------------------------------------------
  // REJECT SHOP
  // -------------------------------------------------------
  Future<bool> rejectShop(String shopId) async {
    final url = Uri.parse("$base/pending/reject/$shopId");

    final res = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer ${AuthService.token}",
      },
    );

    print(res.statusCode);
    print(res.body);

    if (res.statusCode != 200) return false;

    final data = jsonDecode(res.body);
    return data["success"] == true;
  }
}
