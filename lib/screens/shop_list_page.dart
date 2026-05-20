// ignore_for_file: deprecated_member_use, unused_import, use_build_context_synchronously, prefer_const_constructors, avoid_print

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'edit_shop_page.dart';
import 'pending_shops_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'match_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class ShopListPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const ShopListPage({super.key, required this.user});

  @override
  State<ShopListPage> createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage>
    with SingleTickerProviderStateMixin {
  List shops = [];
  List filtered = [];
  bool loading = true;
  String search = "";

  late AnimationController controller;
  late Animation<double> fadeAnim;
  DateTime? callStartTime;
  String role = "";
  String segment = "";
  Timer? callLogTimer;
  int? lastCallTimestamp;

  // ── Zoho Outstanding ──────────────────────────────────
  Map<String, dynamic> zohoData = {};
  bool zohoLoading = false;

  static const Color darkBlue = Color(0xFF002D62);

  @override
  void initState() {
    super.initState();
    role = widget.user["role"].toString().toLowerCase();
    segment = (widget.user["segment"] ?? "").toString().toLowerCase();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    fadeAnim = CurvedAnimation(parent: controller, curve: Curves.easeIn);

    loadShops();
  }

  @override
  void dispose() {
    callLogTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  // ── Load Shops ─────────────────────────────────────────
  Future<void> loadShops() async {
    if (!mounted) return;
    setState(() => loading = true);

    final List res = await ApiService.getShops();

    print("TOTAL SHOPS FROM API: ${res.length}");

    final approved = res.where((shop) {
      return shop["status"] == "approved" && shop["isDeleted"] != true;
    }).toList();

    if (role == "master") {
      filtered = approved;
    } else {
      filtered = approved.where((shop) {
        final shopSeg = (shop["segment"] ?? "").toString().toLowerCase();
        return shopSeg == segment;
      }).toList();
    }

    shops = filtered;

    if (!mounted) return;
    controller.reset();
    controller.forward();
    setState(() => loading = false);

    // ✅ Zoho data background-ல் load பண்ணு
    _loadZohoData();
  }

  // ── Zoho Outstanding Background Load ──────────────────
  Future<void> _loadZohoData() async {
    if (zohoLoading) return;
    setState(() => zohoLoading = true);

    try {
      final data = await ApiService.getShopsOutstanding();
      final List shopsList = data["shops"] ?? [];

      final Map<String, dynamic> mapped = {};
      for (final s in shopsList) {
        final name = (s["shop_name"] ?? "").toString().toLowerCase().trim();
        mapped[name] = s;
      }

      if (mounted) {
        setState(() {
          zohoData = mapped;
          zohoLoading = false;
        });
      }
    } catch (e) {
      print("❌ ZOHO LOAD ERROR => $e");
      if (mounted) setState(() => zohoLoading = false);
    }
  }

  // ── Search ─────────────────────────────────────────────
  List get searchResult {
    final q = search.toLowerCase();
    return shops.where((shop) {
      final name = (shop["shopName"] ?? shop["shop_name"] ?? "")
          .toString()
          .toLowerCase();
      final address = (shop["shopAddress"] ?? shop["address"] ?? "")
          .toString()
          .toLowerCase();
      return name.contains(q) || address.contains(q);
    }).toList();
  }

  // ── Make Call ──────────────────────────────────────────
  Future<void> makeCall(Map<String, dynamic> shop) async {
    final primary = shop["primaryPhone"];
    final secondary = shop["secondaryPhone"];

    String? phone;
    if (primary != null && primary.toString().isNotEmpty) {
      phone = primary.toString();
    } else if (secondary != null && secondary.toString().isNotEmpty) {
      phone = secondary.toString();
    }

    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No phone number available")),
      );
      return;
    }

    callStartTime = DateTime.now();
    final uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) await launchUrl(uri);
    await Future.delayed(const Duration(seconds: 5));
    final duration = DateTime.now().difference(callStartTime!).inSeconds;
    await saveCallLog(shop["shop_id"], phone, duration);
  }

  Future<void> saveCallLog(String shopId, String phone, int duration) async {
    await http.post(
      Uri.parse(
          "https://abhinav-backend.onrender.com/api/shops/$shopId/add-call"),
      headers: {
        "Authorization": "Bearer ${AuthService.token}",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"fromNumber": phone, "durationSec": duration}),
    );
  }

  // ── Image Upload ───────────────────────────────────────
  Future<void> showImageUploadDialog(Map<String, dynamic> shop) async {
    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Upload Shop Image"),
          content: const Text("Select image to upload."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final XFile? pickedFile =
                    await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile == null) return;
                final bytes = await File(pickedFile.path).readAsBytes();
                final base64Image = base64Encode(bytes);
                final ok = await ApiService.updateShopImage(
                    shop["shop_id"], base64Image);
                if (ok) {
                  Navigator.pop(context);
                  await loadShops();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Image uploaded successfully"),
                    backgroundColor: Colors.green,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Upload failed"),
                    backgroundColor: Colors.red,
                  ));
                }
              },
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
  }

  // ── Open Maps ──────────────────────────────────────────
  Future<void> openMaps(double lat, double lng) async {
    final Uri url = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open Google Maps")),
      );
    }
  }

  // ── Format Amount ──────────────────────────────────────
  String _fmt(double v) {
    if (v >= 100000) return "₹${(v / 100000).toStringAsFixed(1)}L";
    if (v >= 1000) return "₹${(v / 1000).toStringAsFixed(1)}K";
    return "₹${v.toStringAsFixed(0)}";
  }

  // ── Build ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final listToShow = searchResult;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF002D62), Color(0xFF005BBB)],
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
                  Row(
                    children: [
                      const Text(
                        "Shop List",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      if (role == "master" || role == "manager")
                        IconButton(
                          icon: const Icon(Icons.pending_actions,
                              color: Colors.white, size: 28),
                          onPressed: () async {
                            final refreshed = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PendingShopsPage(user: widget.user),
                              ),
                            );
                            if (refreshed == true) loadShops();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 25),
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
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) => setState(() => search = v),
                            decoration: InputDecoration(
                              hintText: "Search shops...",
                              prefixIcon: const Icon(Icons.search),
                              filled: true,
                              fillColor: const Color(0xFFF4F7FC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Expanded(
                            child: loading
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : listToShow.isEmpty
                                    ? const Center(
                                        child: Text("No shops found",
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54)))
                                    : FadeTransition(
                                        opacity: fadeAnim,
                                        child: ListView.builder(
                                          itemCount: listToShow.length,
                                          itemBuilder: (_, i) =>
                                              buildShopCard(listToShow[i]),
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

  // ── Shop Card ──────────────────────────────────────────
  Widget buildShopCard(Map<String, dynamic> shop) {
    final double lat = double.tryParse(shop["lat"]?.toString() ?? "0") ?? 0;
    final double lng = double.tryParse(shop["lng"]?.toString() ?? "0") ?? 0;
    final seg = (shop["segment"] ?? "").toString().toUpperCase();
    final String imageUrl = (shop["shopImage"] ?? "").toString();
    final bool imageEmpty = imageUrl.isEmpty;

    // ── Zoho match ──────────────────────────────────────
    final shopName = (shop["shop_name"] ?? shop["shopName"] ?? "")
        .toString()
        .toLowerCase()
        .trim();
    final zoho = zohoData[shopName];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          )
        ],
        border: Border.all(color: Colors.blue.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Shop Header ────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: imageEmpty
                        ? Container(
                            height: 75,
                            width: 75,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.store,
                                size: 28, color: Colors.grey),
                          )
                        : Image.memory(
                            base64Decode(imageUrl),
                            height: 75,
                            width: 75,
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (role == "salesman" && imageEmpty)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: GestureDetector(
                        onTap: () => showImageUploadDialog(shop),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.add,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop["shopName"] ?? shop["shop_name"] ?? "",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            shop["shopAddress"] ?? shop["address"] ?? "",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF005BBB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        seg,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005BBB),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Lat/Lng ────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location,
                    size: 16, color: Color(0xFF005BBB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Lat: ${lat.toStringAsFixed(6)}",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(width: 1, height: 14, color: Colors.grey.shade300),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Lng: ${lng.toStringAsFixed(6)}",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          // ── Zoho Outstanding ───────────────────────────
          _buildZohoSection(zoho),

          const SizedBox(height: 10),

          // ── Salesman Buttons ───────────────────────────
          if (role == "salesman" || role == "manager") ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openMaps(lat, lng),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text("Maps"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF005BBB),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => makeCall(shop),
                    icon: const Icon(Icons.call, size: 18, color: Colors.white),
                    label: const Text("Call",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => MatchPage(shop: shop)),
                      );
                      await loadShops();
                    },
                    icon: const Icon(Icons.verified,
                        size: 18, color: Colors.amber),
                    label: const Text("Match",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Master/Manager Footer ──────────────────────
          if (role == "master" || role == "manager") ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person,
                            size: 14, color: Colors.black54),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          shop["createdByUserName"] ?? "Unknown",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D47A1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit,
                        size: 18, color: Color(0xFF0D47A1)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditShopPage(shop: shop)),
                      ).then((refresh) {
                        if (refresh == true) loadShops();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.red),
                    onPressed: () async {
                      final yes = await showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Delete Shop?"),
                          content: const Text(
                              "Are you sure you want to delete this shop?"),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancel"),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (yes == true) {
                        final id = shop["shop_id"]?.toString();
                        if (id == null || id.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Shop ID missing")),
                          );
                          return;
                        }
                        final ok = await ApiService.deleteShop(id);
                        if (ok) {
                          loadShops();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Shop deleted successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Failed to delete shop"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Zoho Section Widget ────────────────────────────────
  Widget _buildZohoSection(dynamic zoho) {
    // Loading state
    if (zohoLoading && zohoData.isEmpty) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text("Loading Zoho data...",
                style: TextStyle(fontSize: 11, color: Colors.black45)),
          ],
        ),
      );
    }

    // Not matched
    if (zoho == null) {
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.orange.withOpacity(0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, size: 14, color: Colors.orange),
            SizedBox(width: 6),
            Text("Not found in Zoho Books",
                style: TextStyle(fontSize: 11, color: Colors.orange)),
          ],
        ),
      );
    }

    // Matched — show data
    final double outstanding = (zoho["outstanding"] ?? 0).toDouble();
    final double totalBilled = (zoho["total_billed"] ?? 0).toDouble();
    final int invoiceCount = (zoho["invoice_count"] ?? 0) as int;

    Color outColor = Colors.green;
    if (outstanding > 100000) {
      outColor = Colors.red;
    } else if (outstanding > 50000) {
      outColor = Colors.orange;
    } else if (outstanding > 0) {
      outColor = Colors.amber.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          // Total Billed
          Expanded(
            child: Column(
              children: [
                Text(
                  _fmt(totalBilled),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF002D62),
                  ),
                ),
                const SizedBox(height: 2),
                const Text("Total Billed",
                    style: TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          // Outstanding
          Expanded(
            child: Column(
              children: [
                Text(
                  _fmt(outstanding),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: outColor,
                  ),
                ),
                const SizedBox(height: 2),
                const Text("Outstanding",
                    style: TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          // Invoice Count
          Expanded(
            child: Column(
              children: [
                Text(
                  "$invoiceCount",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 2),
                const Text("Invoices",
                    style: TextStyle(fontSize: 10, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
