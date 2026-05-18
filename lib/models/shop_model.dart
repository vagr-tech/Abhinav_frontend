class ShopModel {
  final String id;        // Mongo _id (MAIN)
  final String shopId;    // shop_id (OLD SUPPORT)
  final String shopName;
  final String address;
  final double lat;
  final double lng;
  final String segment;

  ShopModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.address,
    required this.lat,
    required this.lng,
    required this.segment,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    // 🔥 SAFELY PICK ID
    final String mongoId = json["_id"]?.toString() ?? "";
    final String legacyShopId =
        json["shop_id"]?.toString().isNotEmpty == true
            ? json["shop_id"].toString()
            : mongoId;

    return ShopModel(
      id: mongoId,
      shopId: legacyShopId, // 🔥 ALWAYS NON-EMPTY
      shopName:
          json["shop_name"] ?? json["shopName"] ?? "",
      address: json["address"] ?? "",
      // ✅ CHANGE TO
lat: double.tryParse(
  (json["lat"]?.toString() ?? "0").trim().replaceAll(",", ".").replaceAll(" ", "")
) ?? 0,
lng: double.tryParse(
  (json["lng"]?.toString() ?? "0").trim().replaceAll(",", ".").replaceAll(" ", "")
) ?? 0,
      segment: (json["segment"] ?? "").toString().toLowerCase(),
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "shop_id": shopId,          // 🔥 KEEP OLD SUPPORT
        "shop_name": shopName,
        "address": address,
        "lat": lat,
        "lng": lng,
        "segment": segment,
      };
}
