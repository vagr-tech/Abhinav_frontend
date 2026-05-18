// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'dart:convert';
import 'package:abhinav_tracking/screens/home_page.dart';
import 'package:flutter/material.dart';
import '../models/pending_shop_model.dart';
import '../services/pending_shop_service.dart';
import 'full_image_page.dart';

class PendingShopsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool isFromTab; // 🔥 ADD THIS

  const PendingShopsPage({
    super.key,
    required this.user,
    this.isFromTab = false,
  });

  @override
  State<PendingShopsPage> createState() => _PendingShopsPageState();
}

class _PendingShopsPageState extends State<PendingShopsPage> {
  final PendingShopService pendingService = PendingShopService();

  List<PendingShopModel> pendingShops = [];
  bool loading = true;
  bool approving = false; // 🔥 FIX 1
  bool rejecting = false;

  bool get isMaster => widget.user["role"].toString().toLowerCase() == "master";

  bool get isManager =>
      widget.user["role"].toString().toLowerCase() == "manager";

  @override
  void initState() {
    super.initState();
    loadPendingShops();
  }

  // ================= LOAD PENDING SHOPS =================
  Future<void> loadPendingShops() async {
    setState(() => loading = true);

    try {
      final res = await pendingService.getPendingShops();
      pendingShops = res.map((e) => PendingShopModel.fromJson(e)).toList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading pending shops")),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  // ================= APPROVE =================
  Future<void> approveShop(String id) async {
    if (approving) return;

    setState(() => approving = true);

    final ok = await pendingService.approveShop(id);

    setState(() => approving = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shop Approved Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Stay in page and refresh list
      loadPendingShops();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Approval failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================= REJECT =================
  Future<void> rejectShop(String id) async {
    if (rejecting) return;

    setState(() => rejecting = true);
    final ok = await pendingService.rejectShop(id);
    setState(() => rejecting = false);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Shop Rejected",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      loadPendingShops();
    }
  }

  @override
  Widget build(BuildContext context) {
    // SALESMAN BLOCK (UNCHANGED)
    if (!isMaster && !isManager) {
      return const Scaffold(
        body: Center(
          child: Text(
            "Access Denied",
            style: TextStyle(fontSize: 22, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // ✅ CURVED PREMIUM HEADER
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

                  // ✅ HEADER ROW
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          if (widget.isFromTab) {
                            // ✅ Go back safely without creating empty HomePage
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => HomePage(
                                  user: widget.user, // ✅ Pass same user data
                                ),
                              ),
                            );
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Pending Shops",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // ✅ FLOATING WHITE CARD BODY
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
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : pendingShops.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No Pending Shops",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: pendingShops.length,
                                  itemBuilder: (_, i) =>
                                      _pendingCard(pendingShops[i]),
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

  // ================= PENDING CARD =================
  Widget _pendingCard(PendingShopModel shop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(
          color: Colors.blue.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ IMAGE PREVIEW
          if (shop.shopImage != null && shop.shopImage!.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullImagePage(base64Image: shop.shopImage!),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(shop.shopImage!),
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ✅ SHOP NAME + PENDING BADGE
          Row(
            children: [
              Expanded(
                child: Text(
                  shop.shopName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "PENDING",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ✅ DETAILS SECTION
          _infoRow(Icons.location_on, "Address", shop.address),
          const SizedBox(height: 6),
          _infoRow(Icons.category, "Segment", shop.segment),
          const SizedBox(height: 6),
          _infoRow(Icons.person, "Created By", shop.createdByUserName),

          const SizedBox(height: 18),

          // ✅ ACTION BUTTONS (Modern Style)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: approving ? null : () => approveShop(shop.shopId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: approving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Approve",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  onPressed: rejecting ? null : () => rejectShop(shop.shopId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: rejecting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Reject",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D47A1)),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
