import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'call_log_service.dart';
import 'auth_service.dart';
import 'api_service.dart';

Future<void> initializeBackgroundService() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: true,
      initialNotificationTitle: 'Abhinav Tracking',
      initialNotificationContent: 'Location tracking is running',
      foregroundServiceNotificationId: 999,
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: "Abhinav Tracking",
      content: "Location tracking is running",
    );
  }

  // 1 min — live location ping + call log check
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token");
      if (token == null || token.isEmpty) return;

      AuthService.token = token;

      // ✅ Live location — salesman checkin ஆனா மட்டும் ping
      final isTracking = prefs.getBool("live_tracking_active") ?? false;
      if (isTracking) {
        await _sendLocationFromBackground();
      }

      // ✅ Call log check — existing logic
      final raw = prefs.getString("shops_cache");
      if (raw == null || raw.isEmpty) return;

      final shops = jsonDecode(raw);
      await CallLogService.checkCallLogs(shops);
    } catch (e) {
      debugPrint("Background service error: $e");
    }
  });
}

Future<void> _sendLocationFromBackground() async {
  try {
    final Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );

    await ApiService.postLiveLocation(
      lat: pos.latitude,
      lng: pos.longitude,
    );

    debugPrint(
      '📍 BG Sent: (${pos.latitude.toStringAsFixed(5)}, '
      '${pos.longitude.toStringAsFixed(5)}) ✅',
    );
  } catch (e) {
    debugPrint('📍 BG location send error: $e — will retry next minute');
  }
}
