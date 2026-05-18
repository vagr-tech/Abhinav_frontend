// ignore_for_file: use_build_context_synchronously, unused_import, deprecated_member_use, avoid_print

import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../services/auth_service.dart';
import '../services/visit_service.dart';

class MatchPage extends StatefulWidget {
  final dynamic shop;

  const MatchPage({super.key, required this.shop});

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  final VisitService visitService = VisitService();

  bool processing = false;
  String? previewBase64;
  String? uploadedUrl;

  double? distanceMeters;
  double? userLat;
  double? userLng;

  // ---------------------------
  // Distance Calculation
  // ---------------------------
  double calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // ---------------------------
  // CAPTURE → GPS → UPLOAD → SAVE
  // ---------------------------
  Future<void> captureAndMatch() async {
    setState(() => processing = true);

    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    userLat = pos.latitude;
    userLng = pos.longitude;

    double shopLat = double.tryParse(widget.shop["lat"].toString()) ?? 0.0;
    double shopLng = double.tryParse(widget.shop["lng"].toString()) ?? 0.0;

    distanceMeters = calcDistance(userLat!, userLng!, shopLat, shopLng);
    bool isMatch = distanceMeters! <= 50;
    print("Distance sending: $distanceMeters");
    // 🔥 FINAL PAYLOAD (NO EXTRA FIELDS)
    final payload = {
      "shop_id": widget.shop["shop_id"], // ✅ ONLY shop_id
      "shop_name": widget.shop["shop_name"],
      "result": isMatch ? "match" : "mismatch",
      "distance": distanceMeters,
    };

    await visitService.visitShop(payload);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isMatch ? "MATCH ✔ Within 50 meters" : "MISMATCH ❌ Too far from shop",
        ),
        backgroundColor: isMatch ? Colors.green : Colors.red,
      ),
    );

    Navigator.pop(context);
    setState(() => processing = false);
  }

  // ---------------------------
  // UI
  // ---------------------------
  @override
  Widget build(BuildContext context) {
    final s = widget.shop;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // 🔵 PREMIUM CURVED HEADER
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF002D62),
                  Color(0xFF005BBB),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // 🔹 HEADER
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Match Shop",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // 🔹 FLOATING CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🏪 SHOP NAME
                          Row(
                            children: [
                              const Icon(Icons.store, color: Color(0xFF005BBB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  s["shop_name"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // 📍 ADDRESS
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  s["address"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // 🌍 LAT LNG BADGE
                          // 🌍 LAT LNG BADGE (NO OVERFLOW)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.my_location,
                                    size: 16, color: Color(0xFF005BBB)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Lat: ${double.parse(s["lat"].toString()).toStringAsFixed(9)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Lng: ${double.parse(s["lng"].toString()).toStringAsFixed(9)}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 📸 IMAGE PREVIEW
                          if (previewBase64 != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(
                                base64Decode(previewBase64!),
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),

                          const Spacer(),

                          // 📏 DISTANCE DISPLAY
                          if (distanceMeters != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF4F7FC),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.social_distance,
                                      color: Color(0xFF002D62)),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Distance: ${distanceMeters!.toStringAsFixed(1)} m",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 20),

                          // ✅ MATCH BUTTON
                          // ✅ PREMIUM MATCH BUTTON (NOT DULL)
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF005BBB),
                                    Color(0xFF007BFF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: processing ? null : captureAndMatch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.camera_alt,
                                        color: Colors.white),
                                    const SizedBox(width: 10),
                                    Text(
                                      processing
                                          ? "Processing..."
                                          : "Capture & Match",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
