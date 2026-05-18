class PendingShopModel {
  final String shopId; // uuid
  final String shopName;
  final String address;
  final double lat;
  final double lng;
  final String segment;
  final String createdAt;
  final String createdByUserName;
  final String? shopImage; // optional

  PendingShopModel({
    required this.shopId,
    required this.shopName,
    required this.address,
    required this.lat,
    required this.lng,
    required this.segment,
    required this.createdAt,
    required this.createdByUserName,
    this.shopImage,
  });

  factory PendingShopModel.fromJson(Map<String, dynamic> json) {
    return PendingShopModel(
      shopId: json["shop_id"] ?? "",
      shopName: json["shop_name"] ?? json["shopName"] ?? "",
      address: json["address"] ?? "",
      lat: double.tryParse((json["lat"] ?? 0).toString()) ?? 0,
      lng: double.tryParse((json["lng"] ?? 0).toString()) ?? 0,
      segment: (json["segment"] ?? "").toString().toLowerCase(),
      createdAt: json["createdAt"] ?? "",
      createdByUserName:
          json["createdByUserName"] ?? json["createdByUserName"] ?? "Salesman",
      shopImage: json["shopImage"]?.toString(),
    );
  }
}
