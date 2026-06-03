// live_location_service.dart
//
// Cleanup strategy — 3 layers, logout தேவையில்லை:
//
// Layer 1 (Backend TTL):
//   Every POST-ல expireAt = now + 2hr set ஆகும்
//   Salesman ping நிறுத்தினா DynamoDB 2hr-ல auto-delete பண்ணும்
//
// Layer 2 (GET filter):
//   Backend 10 min-க்கு மேல் update ஆகலன்னா response-லயே return பண்ணாது
//   Map-ல dot உடனே disappear ஆகும்
//
// Layer 3 (App lifecycle):
//   App background/close → DELETE call (best effort)
//   Even if this fails, Layer 1 + 2 handle it
//
// pubspec.yaml:
//   geolocator: ^12.0.0

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class LiveLocationService with WidgetsBindingObserver {
  LiveLocationService._();
  static final instance = LiveLocationService._();

  static const Duration _interval = Duration(minutes: 1);

  Timer? _timer;
  bool _running = false;

  // ── Start after salesman login ───────────────────────────
  Future<void> start() async {
    if (_running) return;

    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      debugPrint('📍 LiveLocation: permission denied');
      return;
    }

    _running = true;

    // Register app lifecycle observer — handles background/close
    WidgetsBinding.instance.addObserver(this);

    await _sendLocation(); // send immediately
    _timer = Timer.periodic(_interval, (_) => _sendLocation());

    debugPrint('📍 LiveLocation: started');
  }

  // ── Stop (call on logout if you have one) ────────────────
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
    await ApiService.clearLiveLocation(); // best effort DELETE
    debugPrint('📍 LiveLocation: stopped');
  }

  // ── App lifecycle: background or closed ─────────────────
  // This is the key method — when app is minimized or swiped away
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // App going to background or being killed
      // Fire-and-forget DELETE — TTL is the real backup
      ApiService.clearLiveLocation();
      debugPrint('📍 LiveLocation: app paused/detached → location cleared');
    } else if (state == AppLifecycleState.resumed && _running) {
      // App came back to foreground — resume pinging immediately
      _sendLocation();
      debugPrint('📍 LiveLocation: app resumed → location resumed');
    }
  }

  bool get isRunning => _running;

  Future<void> _sendLocation() async {
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await ApiService.postLiveLocation(lat: pos.latitude, lng: pos.longitude);

      debugPrint(
        '📍 Sent: (${pos.latitude.toStringAsFixed(5)}, '
        '${pos.longitude.toStringAsFixed(5)})',
      );
    } catch (e) {
      debugPrint('📍 LiveLocation send error: $e');
      // Silent fail — next ping in 1 minute
    }
  }

  Future<bool> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }
}
