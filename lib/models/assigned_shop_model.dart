class AssignedShopModel {
  final String id;
  final String userId;
  final String shopId;
  final int sequence;
  final String assignedAt;

  AssignedShopModel({
    required this.id,
    required this.userId,
    required this.shopId,
    required this.sequence,
    required this.assignedAt,
  });

  factory AssignedShopModel.fromJson(Map<String, dynamic> json) {
    return AssignedShopModel(
      id: json["_id"]?.toString() ?? "",
      userId: json["user_id"] ?? "",
      shopId: json["shop_id"] ?? "",
      sequence: json["sequence"] ?? 0,
      assignedAt: json["assigned_at"] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "user_id": userId,
        "shop_id": shopId,
        "sequence": sequence,
        "assigned_at": assignedAt,
      };
}
