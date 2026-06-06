// lib/widgets/animated_bike_marker.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

class AnimatedBikeMarker extends StatefulWidget {
  final LatLng fromPoint;
  final LatLng toPoint;
  final String salesmanName;
  final bool isStale;
  final Duration duration;

  const AnimatedBikeMarker({
    super.key,
    required this.fromPoint,
    required this.toPoint,
    required this.salesmanName,
    this.isStale = false,
    this.duration = const Duration(seconds: 45), // 1 min ping → 45s glide
  });

  @override
  State<AnimatedBikeMarker> createState() => _AnimatedBikeMarkerState();
}

class _AnimatedBikeMarkerState extends State<AnimatedBikeMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  LatLng _from = const LatLng(0, 0);
  LatLng _to = const LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _from = widget.fromPoint;
    _to = widget.toPoint;

    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);

    if (!widget.isStale) _ctrl.forward();
  }

  @override
  void didUpdateWidget(AnimatedBikeMarker old) {
    super.didUpdateWidget(old);

    // New ping வந்தா → current interpolated position-இல் இருந்து animate
    if (old.toPoint != widget.toPoint) {
      final currentLat = _lerp(_from.latitude, _to.latitude, _anim.value);
      final currentLng = _lerp(_from.longitude, _to.longitude, _anim.value);

      setState(() {
        _from = LatLng(currentLat, currentLng);
        _to = widget.toPoint;
      });

      _ctrl.reset();
      if (!widget.isStale) _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  // Bearing: bike எந்த direction-ல போகுது என்று calculate
  double _bearing(LatLng from, LatLng to) {
    final dLng = (to.longitude - from.longitude) * pi / 180;
    final lat1 = from.latitude * pi / 180;
    final lat2 = to.latitude * pi / 180;
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    return atan2(y, x); // radians
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final lat = _lerp(_from.latitude, _to.latitude, _anim.value);
        final lng = _lerp(_from.longitude, _to.longitude, _anim.value);
        // ignore lat/lng here — parent Marker handles position
        // We use bearing for rotation

        final bearing = _bearing(_from, _to);
        final isMoving = (_to.latitude - _from.latitude).abs() > 0.00001 ||
            (_to.longitude - _from.longitude).abs() > 0.00001;

        final bikeColor =
            widget.isStale ? Colors.grey : const Color(0xFF00C853);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: widget.isStale
                    ? Colors.grey.shade700
                    : const Color(0xFF003300),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.salesmanName.split(' ').first,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 3),

            // Bike icon — direction-க்கு rotate
            Transform.rotate(
              angle: isMoving ? bearing : 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.isStale
                      ? Colors.grey.shade200
                      : const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: bikeColor,
                    width: 2,
                  ),
                  boxShadow: widget.isStale
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF00C853).withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                ),
                padding: const EdgeInsets.all(5),
                child: SvgPicture.asset(
                  'assets/icon/bike.svg',
                  colorFilter: ColorFilter.mode(bikeColor, BlendMode.srcIn),
                ),
              ),
            ),

            // Status label
            const SizedBox(height: 2),
            Text(
              widget.isStale ? '${widget.salesmanName}' : 'Live',
              style: TextStyle(
                fontSize: 8,
                color: widget.isStale ? Colors.grey : const Color(0xFF00C853),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
