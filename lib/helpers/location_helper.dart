import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationHelper {
  /// Request GPS permission + return location
  static Future<Position?> getLocation() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Haversine Formula
  static double distanceInMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lng2 - lng1) * p)) / 2;

    return 12742 * asin(sqrt(a)) * 1000; // in meters
  }
}
