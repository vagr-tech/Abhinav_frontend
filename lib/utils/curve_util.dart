// lib/utils/curve_util.dart
import 'package:latlong2/latlong.dart';

class CurveUtil {
  /// Catmull-Rom spline — GPS points list → smooth curved points list
  /// [segments] = ஒவ்வொரு 2 points-க்கும் இடையில் எத்தனை intermediate points
  static List<LatLng> smooth(List<LatLng> points, {int segments = 16}) {
    if (points.length < 3) return points; // 2 or less → straight ok

    final result = <LatLng>[];

    // Ghost points: first & last point duplicate பண்ணு (spline boundary fix)
    final pts = [points.first, ...points, points.last];

    for (int i = 1; i < pts.length - 2; i++) {
      final p0 = pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2];

      // Segment start point always add
      result.add(p1);

      // Intermediate points
      for (int s = 1; s < segments; s++) {
        final t = s / segments;
        final t2 = t * t;
        final t3 = t2 * t;

        // Catmull-Rom formula (tension = 0.5)
        final lat = 0.5 *
            ((2 * p1.latitude) +
                (-p0.latitude + p2.latitude) * t +
                (2 * p0.latitude -
                        5 * p1.latitude +
                        4 * p2.latitude -
                        p3.latitude) *
                    t2 +
                (-p0.latitude +
                        3 * p1.latitude -
                        3 * p2.latitude +
                        p3.latitude) *
                    t3);

        final lng = 0.5 *
            ((2 * p1.longitude) +
                (-p0.longitude + p2.longitude) * t +
                (2 * p0.longitude -
                        5 * p1.longitude +
                        4 * p2.longitude -
                        p3.longitude) *
                    t2 +
                (-p0.longitude +
                        3 * p1.longitude -
                        3 * p2.longitude +
                        p3.longitude) *
                    t3);

        result.add(LatLng(lat, lng));
      }
    }

    // Last point add
    result.add(points.last);
    return result;
  }
}
