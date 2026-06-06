import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart'; // ← ADD
import '../services/api_service.dart';

class LiveLocationService with WidgetsBindingObserver {
  LiveLocationService._();
  static final instance = LiveLocationService._();

  static const Duration _interval = Duration(minutes: 1);

  Timer? _timer;
  bool _running = false;

  // ─── START ────────────────────────────────────────────────────
  Future<void> start() async {
    if (_running) return;

    final hasPermission = await _requestAllPermissions(); // ← FIXED
    if (!hasPermission) {
      debugPrint('📍 LiveLocation: permission denied — cannot start');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("live_tracking_active", true);

    _running = true;
    WidgetsBinding.instance.addObserver(this);

    // Immediate first ping
    await _sendLocation();
    _startTimer();

    debugPrint('📍 LiveLocation: started ✅');
  }

  // ─── STOP ─────────────────────────────────────────────────────
  Future<void> stop() async {
    if (!_running) return;

    _cancelTimer();
    _running = false;
    WidgetsBinding.instance.removeObserver(this);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("live_tracking_active", false);

    // ✅ DELETE இல்லை — isCheckedOut: true மட்டும் set
    // Route history தெரியும், live dot மட்டும் மறையும்
    try {
      await ApiService.checkoutLiveLocation();
      debugPrint('🛑 Checkout flagged in DB ✅');
    } catch (e) {
      debugPrint('🛑 Checkout flag error: $e');
    }

    debugPrint('📍 LiveLocation: stopped ✅');
  }

  bool get isRunning => _running;

  // ─── LIFECYCLE ────────────────────────────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📍 LiveLocation lifecycle: $state');

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Foreground timer cancel — BG service引き継ぐ
        _cancelTimer();
        debugPrint('📍 App paused — BG service takes over');
        break;

      case AppLifecycleState.resumed:
        if (_running) {
          // BG service இருந்தாலும் foreground timer restart பண்ணு
          // (duplicate ping ok — DynamoDB overwrite ஆகும்)
          _sendLocation();
          _startTimer();
          debugPrint('📍 App resumed — foreground timer restarted');
        }
        break;

      default:
        break;
    }
  }

  // ─── TIMER ────────────────────────────────────────────────────
  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(_interval, (_) => _sendLocation());
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── SEND ─────────────────────────────────────────────────────
  Future<void> _sendLocation() async {
    try {
      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      await ApiService.postLiveLocation(
        lat: pos.latitude,
        lng: pos.longitude,
      );

      debugPrint('📍 FG Sent: (${pos.latitude.toStringAsFixed(5)}, '
          '${pos.longitude.toStringAsFixed(5)}) ✅');
    } catch (e) {
      debugPrint('📍 FG send error: $e');
    }
  }

  // ─── PERMISSIONS ──────────────────────────────────────────────
  Future<bool> _requestAllPermissions() async {
    // Step 1: Fine location
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('📍 Location service OFF');
      return false;
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      debugPrint('📍 Location permission denied forever');
      return false;
    }

    // Step 2: Background location (Android 10+)
    // "Allow all the time" — OS dialog-ல user choose பண்ணணும்
    final bgStatus = await Permission.locationAlways.status;
    if (!bgStatus.isGranted) {
      final result = await Permission.locationAlways.request();
      if (!result.isGranted) {
        debugPrint('📍 Background location not granted — FG only');
        // ❌ Return false பண்ணாதே — FG tracking still works
        // BG service-ல skip ஆகும், foreground-ல work ஆகும்
      }
    }

    return true;
  }
}
