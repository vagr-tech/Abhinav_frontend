// ignore_for_file: unused_local_variable, use_build_context_synchronously, avoid_print, unnecessary_const, deprecated_member_use

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AssignedShopsScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const AssignedShopsScreen({super.key, required this.user});

  @override
  State<AssignedShopsScreen> createState() => _AssignedShopsScreenState();
}

class _AssignedShopsScreenState extends State<AssignedShopsScreen> {
  List<dynamic> shops = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAssignedShops();
  }

  String formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return "${dt.day}-${dt.month}-${dt.year}";
    } catch (e) {
      return "";
    }
  }

  Future<void> loadAssignedShops() async {
    setState(() => loading = true);

    final role = widget.user["role"].toString().toLowerCase();
    final mySegment = widget.user["segment"];

    final assigned =
        await ApiService.getAssignedShops(widget.user["user_id"].toString());
    final allShops = await ApiService.getShops();

    List filtered = [];

    if (role == "master") {
      filtered = assigned;
    } else if (role == "manager") {
      filtered = assigned
          .where((a) =>
              (a["segment"] ?? "").toString().toLowerCase() ==
              (mySegment ?? "").toString().toLowerCase())
          .toList();
    } else {
      filtered = assigned
          .where((a) =>
              a["salesman_id"].toString() == widget.user["user_id"].toString())
          .toList();
    }

    final mapped = filtered.map((a) {
      final match = allShops.firstWhere(
        (s) => s["shop_id"].toString() == a["shop_id"].toString(),
        orElse: () => <String, dynamic>{},
      );

      return {
        "_id": a["_id"] ?? a["shop_id"],
        "sk": a["sk"],
        "shop_id": a["shop_id"],
        "salesmanId": a["salesmanId"], // 👈 MUST ADD
        "shop_name": match["shop_name"] ?? a["shop_name"] ?? "",
        "address": match["address"] ?? a["address"] ?? "",
        "segment": a["segment"] ?? match["segment"] ?? "",
        "sequence": int.tryParse(a["sequence"]?.toString() ?? "0") ?? 0,
        "assignedTo": a["salesmanName"] ?? "",
        "assignedDate": a["createdAt"] ?? "",
      };
    }).toList();

    mapped.sort((a, b) => (a["sequence"] ?? 0).compareTo(b["sequence"] ?? 0));

    if (!mounted) return;

    setState(() {
      shops = mapped;
      loading = false;
    });
  }

  Future<void> _changeAssignmentDate(Map shop) async {
    print("EDIT CLICKED");
    print("SALESMAN ID => ${shop["salesmanId"]}");
    print("OLD SK => ${shop["sk"]}");

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (picked == null) return;

    final newDate =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";

    print("NEW DATE => $newDate");

    final ok = await ApiService.modifyAssignmentDate(
      salesmanId: shop["salesmanId"],
      oldSk: shop["sk"],
      newDate: newDate,
    );

    print("API RESULT => $ok");

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            ok ? "Assignment date updated" : "Failed to update assignment"),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) loadAssignedShops();
  }

  Future<void> saveOrder() async {
    final ok = await ApiService.reorderAssignedShops(
      widget.user["user_id"].toString(),
      shops.map<String>((e) => e["sk"].toString()).toList(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? "Order Updated" : "Update Failed"),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) loadAssignedShops();
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user["role"].toString().toLowerCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 260, // little extra smooth look
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Assigned Shops",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.user["name"] ?? "",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        ],
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
                      child: loading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : shops.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No assigned shops",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                )
                              : ReorderableListView.builder(
                                  itemCount: shops.length,
                                  onReorder: (oldIndex, newIndex) {
                                    if (role == "master" || role == "manager") {
                                      setState(() {
                                        if (newIndex > oldIndex) newIndex--;
                                        final item = shops.removeAt(oldIndex);
                                        shops.insert(newIndex, item);
                                      });
                                    }
                                  },
                                  itemBuilder: (context, i) {
                                    return _shopCard(shops[i], i, role);
                                  },
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

  Widget _shopCard(Map shop, int i, String role) {
    return Container(
      key: ValueKey(shop["_id"]),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔵 Number Badge
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF002D62), Color(0xFF005BBB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "${i + 1}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 📦 Shop Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Name
                Text(
                  shop["shop_name"] ?? "",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D47A1),
                  ),
                ),

                const SizedBox(height: 4),

                // Address
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.redAccent),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop["address"] ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Segment + Assigned To in single row
                Row(
                  children: [
                    const Icon(Icons.category,
                        size: 14, color: Colors.blueGrey),
                    const SizedBox(width: 4),
                    Text(
                      shop["segment"] ?? "",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.person, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        shop["assignedTo"] ?? "",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      formatDate(shop["assignedDate"]),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ✏️ Edit & 🗑 Delete (Only for manager/master)
          if (role == "manager" || role == "master")
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () {
                    _changeAssignmentDate(shop);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  onPressed: () {
                    // TODO: Call delete API
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }
}
