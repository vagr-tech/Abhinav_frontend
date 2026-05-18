// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'call_log_service.dart';
import 'auth_service.dart';

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

  Timer.periodic(const Duration(seconds: 20), (timer) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final token = prefs.getString("token");
      if (token == null || token.isEmpty) return;

      AuthService.token = token;

      final raw = prefs.getString("shops_cache");
      if (raw == null || raw.isEmpty) return;

      final shops = jsonDecode(raw);

      await CallLogService.checkCallLogs(shops);
    } catch (e) {
      debugPrint("Background service error: $e");
    }
  });
}