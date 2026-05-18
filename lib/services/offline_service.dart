import 'package:hive/hive.dart';
import '../models/offline_shop.dart';

class OfflineService {
  static const String boxName = "offlineShops";

  static Future<void> saveOfflineShop(OfflineShop shop) async {
    final box = await Hive.openBox<OfflineShop>(boxName);
    await box.add(shop);
  }

  static Future<List<OfflineShop>> getOfflineShops() async {
    final box = await Hive.openBox<OfflineShop>(boxName);
    return box.values.toList();
  }

  static Future<void> removeShop(int index) async {
    final box = await Hive.openBox<OfflineShop>(boxName);
    await box.deleteAt(index);
  }

  static Future<int> count() async {
    final box = await Hive.openBox<OfflineShop>(boxName);
    return box.length;
  }
}
