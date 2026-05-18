// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:call_log/call_log.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class CallLogService {
  static Timer? _timer;
  static int? lastCallTimestamp;

  static void start(List shops) {
    print("CallLogService started");

    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        checkCallLogs(shops);
      },
    );
  }

  static String normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length <= 10) return digits;

    return digits.substring(digits.length - 10);
  }

 static Future<void> checkCallLogs(List shops) async {
  print("Checking call logs...");

  Iterable<CallLogEntry> entries = await CallLog.get();

  if (entries.isEmpty) return;

  final now = DateTime.now();

  final todayStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;

  final nowMillis = DateTime.now().millisecondsSinceEpoch;

  for (var entry in entries) {

    final number = entry.number ?? "";
    final duration = entry.duration ?? 0;
    final timestamp = entry.timestamp ?? 0;

    // skip calls from previous days
    if (timestamp < todayStart) continue;

    // skip missed calls
    if (duration == 0) continue;

    // wait for android to update duration
    if (nowMillis - timestamp < 10000) continue;

    // skip duplicates
    if (lastCallTimestamp != null && timestamp <= lastCallTimestamp!) {
      continue;
    }

    final normalizedNumber = normalizePhone(number);

    for (var shop in shops) {

      final primary = normalizePhone(shop["primaryPhone"] ?? "");
      final secondary = normalizePhone(shop["secondaryPhone"] ?? "");

      if (normalizedNumber.endsWith(primary) ||
          normalizedNumber.endsWith(secondary)) {

        print("Matched shop ${shop["shop_name"]}");
        print("Saving call $normalizedNumber duration $duration");

        await saveCallLog(
          shop["shop_id"],
          normalizedNumber,
          duration,
        );

        break;
      }
    }

    if (lastCallTimestamp == null || timestamp > lastCallTimestamp!) {
      lastCallTimestamp = timestamp;
    }

  }
}
  static Future<void> saveCallLog(
      String shopId, String phone, int duration) async {
    try {
      await http.post(
        Uri.parse(
            "https://abhinav-backend.onrender.com/api/shops/$shopId/add-call"),
        headers: {
          "Authorization": "Bearer ${AuthService.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "fromNumber": phone,
          "durationSec": duration,
        }),
      );
    } catch (e) {
      print("Call log save error $e");
    }
  }
}
