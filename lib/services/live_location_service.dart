import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LiveLocationService with WidgetsBindingObserver {
  LiveLocationService._();
  static final instance = LiveLocationService._();

  static const Duration _interval = Duration(minutes: 1);

  Timer? _timer;
  bool _running = false;

  Future<void> start() async {
    if (_running) return;

    final hasPermission = await _checkPermission();
    if (!hasPermission) return;

    // ✅ Background service-க்கு flag
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("live_tracking_active", true);

    _running = true;
    WidgetsBinding.instance.addObserver(this);
    await _sendLocation();
    _startTimer();

    debugPrint('📍 LiveLocation: started ✅');
  }

  Future<void> stop() async {
    if (!_running) return;

    _cancelTimer();
    _running = false;
    WidgetsBinding.instance.removeObserver(this);

    // ✅ Background service-க்கு flag off
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("live_tracking_active", false);

    // ❌ clearLiveLocation() — DELETE பண்ணாதே
    debugPrint('📍 LiveLocation: stopped ✅');
  }

  bool get isRunning => _running;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📍 LiveLocation: lifecycle → $state');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // ❌ clearLiveLocation() — DELETE பண்ணாதே
      _cancelTimer(); // timer மட்டும் cancel
    } else if (state == AppLifecycleState.resumed && _running) {
      _sendLocation();
      _startTimer();
      debugPrint('📍 LiveLocation: resumed → ping sent, timer restarted');
    }
  }

  void _startTimer() {
    _cancelTimer();
    _timer = Timer.periodic(_interval, (_) {
      debugPrint('📍 LiveLocation: timer tick → sending location');
      _sendLocation();
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

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

      debugPrint(
        '📍 Sent: (${pos.latitude.toStringAsFixed(5)}, '
        '${pos.longitude.toStringAsFixed(5)}) ✅',
      );
    } catch (e) {
      debugPrint('📍 LiveLocation send error: $e — will retry next minute');
    }
  }

  Future<bool> _checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      debugPrint('📍 Location service disabled');
      return false;
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return perm != LocationPermission.denied &&
        perm != LocationPermission.deniedForever;
  }
}
