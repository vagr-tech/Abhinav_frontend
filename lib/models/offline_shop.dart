import 'package:hive/hive.dart';

part 'offline_shop.g.dart';

@HiveType(typeId: 1)
class OfflineShop {

  @HiveField(0)
  String shopName;

  @HiveField(1)
  String address;

  @HiveField(2)
  String base64Image;

  @HiveField(3)
  double lat;

  @HiveField(4)
  double lng;

  @HiveField(5)
  String segment;

  @HiveField(6)
  String createdBy;

  OfflineShop({
    required this.shopName,
    required this.address,
    required this.base64Image,
    required this.lat,
    required this.lng,
    required this.segment,
    required this.createdBy,
  });
}
