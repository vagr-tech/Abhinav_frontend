class LogModel {
  final String userId;
  final String shopId;
  final String shopName;
  final String salesman;
  final String date;
  final String time;
  final String datetime;

  LogModel({
    required this.userId,
    required this.shopId,
    required this.shopName,
    required this.salesman,
    required this.date,
    required this.time,
    required this.datetime,
  });

  Map<String, dynamic> toJson() => {
        "salesmanId": userId,
        "salesman_name": salesman,
        "shop_id": shopId,
        "shop_name": shopName,
        "visit_date": date,
        "visit_time": time,
        "datetime": datetime,
        "photo_url": "uploaded_url_dummy",
        "distance": 0,
        "result": "match",
      };
}
