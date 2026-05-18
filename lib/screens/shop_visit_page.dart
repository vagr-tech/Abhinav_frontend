// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

import '../services/log_service.dart';
import '../services/auth_service.dart';
import '../models/shop_model.dart';
import '../models/log_model.dart';

class ShopVisitPage extends StatefulWidget {
  final ShopModel shop;
  const ShopVisitPage({super.key, required this.shop});

  @override
  State<ShopVisitPage> createState() => _ShopVisitPageState();
}

class _ShopVisitPageState extends State<ShopVisitPage> {
  final logService = LogService();
  bool loading = false;
  File? selectedImage;

  final ImagePicker picker = ImagePicker();
  Position? currentPos;

  // -------------------------------------------------------
  // CAMERA
  // -------------------------------------------------------
  Future pickFromCamera() async {
    final XFile? img = await picker.pickImage(source: ImageSource.camera);
    if (img != null) {
      if (!mounted) return;
      setState(() => selectedImage = File(img.path));
    }
  }

  // -------------------------------------------------------
  // GALLERY
  // -------------------------------------------------------
  Future pickFromGallery() async {
    final XFile? img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      if (!mounted) return;
      setState(() => selectedImage = File(img.path));
    }
  }

  // -------------------------------------------------------
  // LOCATION
  // -------------------------------------------------------
  Future<bool> getCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return false;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return false;
      }

      currentPos =
          await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      return true;
    } catch (_) {
      return false;
    }
  }

  // -------------------------------------------------------
  // DISTANCE (meters)
  // -------------------------------------------------------
  double _distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  // -------------------------------------------------------
  // SAVE VISIT
  // -------------------------------------------------------
  Future<void> saveVisit() async {
    if (selectedImage == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please take a photo before submitting")),
      );
      return;
    }

    if (!mounted) return;
    setState(() => loading = true);

    final user = AuthService.currentUser!;
    final now = DateTime.now();

    final dateStr =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    // 1) Location
    final gotLocation = await getCurrentLocation();
    if (!mounted) return;

    if (!gotLocation || currentPos == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Unable to get GPS location")));
      return;
    }

    // 2) Distance
    final dist = _distanceMeters(
      currentPos!.latitude,
      currentPos!.longitude,
      widget.shop.lat,
      widget.shop.lng,
    );

    final result = dist <= 200 ? "match" : "mismatch";

    // 3) Upload Image
    final bytes = await selectedImage!.readAsBytes();
    final base64Image = base64Encode(bytes);

    final uploadedUrl = await logService.uploadPhoto(
      base64Image,
      "visit_${now.millisecondsSinceEpoch}.jpg",
    );

    if (!mounted) return;

    if (uploadedUrl == null) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Photo upload failed")));
      return;
    }

    // 4) Build LogModel + convert to JSON
   final log = LogModel(
  userId: user["user_id"],
  shopId: widget.shop.shopId,
  shopName: widget.shop.shopName,
  salesman: user["name"],
  date: dateStr,
  time: timeStr,
  datetime: now.toIso8601String(),
);

    // 🔥 FIX: Convert LogModel → JSON before sending
    final ok = await logService.saveVisit(log.toJson());

    if (!mounted) return;
    setState(() => loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result == "match"
              ? "Visit saved (MATCH)"
              : "Outside shop location (MISMATCH)"),
        ),
      );
      Navigator.pop(context, true); // 🔥 IMPORTANT

    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Failed to save visit")));
    }
  }

  // -------------------------------------------------------
  // UI
  // -------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF007BFF),
              Color(0xFF66B2FF),
              Color(0xFFB8E0FF),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        size: 28, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.shop.shopName,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                          image: selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(selectedImage!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: selectedImage == null
                            ? const Center(
                                child: Text(
                                  "No photo selected",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: pickFromCamera,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Camera"),
                          ),
                          ElevatedButton.icon(
                            onPressed: pickFromGallery,
                            icon: const Icon(Icons.photo),
                            label: const Text("Gallery"),
                          ),
                        ],
                      ),

                      const Spacer(),

                      loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: saveVisit,
                                child: const Text("Submit Visit"),
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
    );
  }
}
