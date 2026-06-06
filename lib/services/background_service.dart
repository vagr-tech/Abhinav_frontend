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
      notificationChannelId:
          'abhinav_tracking_channel', // ← FIXED: dedicated channel
      initialNotificationTitle: 'Abhinav Tracking Active',
      initialNotificationContent: '📍 Location tracking is running',
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
    // ← CRITICAL: setAsForegroundService() call பண்ணாட்டா notification போயிடும்
    service.setAsForegroundService();

    service.setForegroundNotificationInfo(
      title: "Abhinav Tracking Active",
      content: "📍 Location tracking is running",
    );
  }

  // Service kill signal
  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // ← FIXED: 1 min timer
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    try {
      // Service alive-ஆ இருக்கா check
      if (service is AndroidServiceInstance) {
        if (!await service.isForegroundService()) {
          service.setAsForegroundService(); // Re-assert foreground
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      if (token == null || token.isEmpty) return;

      AuthService.token = token;

      // ─── Live location ping ───────────────────────────────────
      final isTracking = prefs.getBool("live_tracking_active") ?? false;
      if (isTracking) {
        await _sendLocationFromBackground();
      }

      // ─── Call log (existing logic) ────────────────────────────
      final raw = prefs.getString("shops_cache");
      if (raw == null || raw.isEmpty) return;
      final shops = jsonDecode(raw);
      await CallLogService.checkCallLogs(shops);
    } catch (e) {
      debugPrint("BG service error: $e");
    }
  });
}

Future<void> _sendLocationFromBackground() async {
  try {
    // ← FIXED: Background permission check
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      debugPrint('📍 BG: No location permission — skipping');
      return;
    }

    final Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15), // 10→15: BG-ல slow ஆ இருக்கும்
    );

    await ApiService.postLiveLocation(
      lat: pos.latitude,
      lng: pos.longitude,
    );

    debugPrint('📍 BG Sent: (${pos.latitude.toStringAsFixed(5)}, '
        '${pos.longitude.toStringAsFixed(5)}) ✅');
  } catch (e) {
    debugPrint('📍 BG location error: $e');
    // Don't rethrow — next minute retry
  }
}
