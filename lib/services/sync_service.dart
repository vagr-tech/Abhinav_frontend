import 'package:http/http.dart' as http;
import 'dart:convert';
import 'offline_service.dart';
import '../models/offline_shop.dart';
import '../services/auth_service.dart';

class SyncService {
  static Future syncOfflineShops() async {
    final shops = await OfflineService.getOfflineShops();

    if (shops.isEmpty) return;

    for (int i = 0; i < shops.length; i++) {
      OfflineShop s = shops[i];

      final url = Uri.parse("https://abhinav-backend.onrender.com/api/pending/add");

      try {
        final res = await http.post(
          url,
          headers: {
            "Authorization": "Bearer ${AuthService.token}",
            "Content-Type": "application/json"
          },
          body: jsonEncode({
            "shop_name": s.shopName,
            "address": s.address,
            "lat": s.lat,
            "lng": s.lng,
            "image": s.base64Image,
            "segment": s.segment,
            "created_by": s.createdBy
          }),
        );

        if (res.statusCode == 200) {
          await OfflineService.removeShop(i);
        }

      } catch (e) {
        return; // stop sync if internet fails
      }
    }
  }
}
