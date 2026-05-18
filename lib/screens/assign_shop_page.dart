// ignore_for_file: avoid_print, unused_import, deprecated_member_use

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/user_model.dart';
import '../models/shop_model.dart';
import '../services/user_service.dart';
import '../services/shop_service.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart' as api;

class AssignShopPage extends StatefulWidget {
  const AssignShopPage({super.key});

  @override
  State<AssignShopPage> createState() => _AssignShopPageState();
}

class _AssignShopPageState extends State<AssignShopPage> {
  List<UserModel> users = [];
  List<ShopModel> allShops = [];
  List<ShopModel> segmentShops = [];

  UserModel? selectedUser;
  Position? userLocation;

  /// 🔥 IMPORTANT → ONLY Mongo `_id`
  List<String> selectedShopIds = [];

  bool loading = true;
  TextEditingController searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInitial();
  }

  // =============================
  // LOAD USERS & SHOPS
  // =============================
  Future<void> loadInitial() async {
    setState(() => loading = true);

    String role = AuthService.currentUser?["role"] ?? "";
    String segment = AuthService.currentUser?["segment"] ?? "";

    users = await UserService().getUsers();
    allShops = await ShopService().getShops();

    // MANAGER → segment filter
    if (role == "manager") {
      users = users
          .where((u) => u.segment.toLowerCase() == segment.toLowerCase())
          .toList();

      allShops = allShops
          .where((s) => s.segment.toLowerCase() == segment.toLowerCase())
          .toList();
    }

    setState(() => loading = false);
  }

  // =============================
  // FILTER SHOPS BY USER SEGMENT
  // =============================
  void filterShops() {
    if (selectedUser == null) return;

    final userSegment = selectedUser!.segment.toLowerCase();

    setState(() {
      segmentShops = allShops.where((s) {
        final shopSegment = s.segment.toLowerCase();

        // 🔥 master / all → show all shops
        if (userSegment == "all") return true;

        return shopSegment == userSegment;
      }).toList();

      selectedShopIds.clear();
    });
  }

  // =============================
  // LOCATION
  // =============================
  Future<void> getUserLocation() async {
    try {
      userLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      userLocation = Position(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  // =============================
  // DISTANCE (SORTING)
  // =============================
  double distance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLon / 2) *
            sin(dLon / 2);

    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  // =============================
  // ASSIGN SHOPS
  // =============================
  Future<void> assignShopsToSalesman() async {
    if (selectedUser == null) {
      showMsg("Select a user first");
      return;
    }

    if (selectedShopIds.isEmpty) {
      showMsg("Select at least one shop");
      return;
    }

    await getUserLocation();

    List<Map<String, dynamic>> arranged = [];

    // Step A: Filter selected shops
    for (var shop in segmentShops) {
      if (selectedShopIds.contains(shop.shopId)) {
        arranged.add({
          "shop": shop,
          "distance": distance(
            userLocation!.latitude,
            userLocation!.longitude,
            shop.lat,
            shop.lng,
          ),
        });
      }
    }

    arranged.sort((a, b) => a["distance"].compareTo(b["distance"]));

    // ✅ Step 1: Build shopsPayload HERE
    List<Map<String, dynamic>> shopsPayload = arranged.map((s) {
      final ShopModel shop = s["shop"];

      return {
        "shop_id": shop.shopId,   
        "shop_name": shop.shopName,
        "address": shop.address,
        "segment": shop.segment,
      };
    }).toList();

    // Step 2: Call API once
   final success = await api.ApiService.resetAndAssign(
  selectedUser!.id.toString(),
  selectedUser!.name,
  shopsPayload,
);

    if (!mounted) return;

    if (success) {
      showMsg("Shops Assigned Successfully 🎉", color: Colors.green);
    } else {
      showMsg("Shop Assignment Failed ❌");
    }

    setState(() {
      selectedShopIds.clear();
    });
  }

  void showMsg(String t, {Color color = Colors.black}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t),
        backgroundColor: color,
      ),
    );
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    String role = AuthService.currentUser?["role"] ?? "";

    if (role != "master" && role != "manager") {
      return const Scaffold(
        body: Center(
          child: Text(
            "Access Denied",
            style: TextStyle(color: Colors.red, fontSize: 20),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // 🔵 PREMIUM HEADER
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
                  const SizedBox(height: 15),

                  const Text(
                    "Assign Shops",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 🔹 FLOATING WHITE CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
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
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              children: [
                                // 👤 USER DROPDOWN
                                DropdownButtonFormField<UserModel>(
                                  value: selectedUser,
                                  decoration: customInput("Select Salesman"),
                                  dropdownColor: Colors.white,
                                  items: users
                                      .map(
                                        (u) => DropdownMenuItem(
                                          value: u,
                                          child: Text(
                                            "${u.name} (${u.segment})",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (u) {
                                    selectedUser = u;
                                    filterShops();
                                  },
                                ),

                                const SizedBox(height: 16),

                                // 🔍 SEARCH
                                TextField(
                                  controller: searchCtrl,
                                  decoration:
                                      customInput("Search shops").copyWith(
                                    prefixIcon: const Icon(Icons.search),
                                  ),
                                  onChanged: (txt) {
                                    if (selectedUser == null) return;

                                    setState(() {
                                      segmentShops = allShops
                                          .where((s) =>
                                              s.segment.toLowerCase() ==
                                              selectedUser!.segment
                                                  .toLowerCase())
                                          .where((s) =>
                                              s.shopName.toLowerCase().contains(
                                                  txt.toLowerCase()) ||
                                              s.address
                                                  .toLowerCase()
                                                  .contains(txt.toLowerCase()))
                                          .toList();
                                    });
                                  },
                                ),

                                const SizedBox(height: 18),

                                // 🏪 SHOP LIST
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: segmentShops.length,
                                    itemBuilder: (_, i) {
                                      final shop = segmentShops[i];
                                      final isChecked =
                                          selectedShopIds.contains(shop.shopId);

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 14),
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4F7FC),
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          border: Border.all(
                                            color:
                                                Colors.blue.withOpacity(0.12),
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          value: isChecked,
                                          activeColor: const Color(0xFF002D62),
                                          title: Text(
                                            shop.shopName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: Color(0xFF0D47A1),
                                            ),
                                          ),
                                          subtitle: Text(
                                            shop.address,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
                                            ),
                                          ),
                                          onChanged: (v) {
                                            setState(() {
                                              if (v == true) {
                                                selectedShopIds
                                                    .add(shop.shopId);
                                              } else {
                                                selectedShopIds
                                                    .remove(shop.shopId);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // ✅ ASSIGN BUTTON
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: assignShopsToSalesman,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF002D62),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      "Assign Selected Shops",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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

  InputDecoration customInput(String label) {
    return InputDecoration(
      hintText: label,
      filled: true,
      fillColor: const Color(0xFFF4F7FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF002D62),
          width: 1.5,
        ),
      ),
    );
  }
}
