// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../services/api_service.dart' as api;

class ModifyAssignedPage extends StatefulWidget {
  final String salesmanId;
  final String salesmanName;
  final List currentShops;

  const ModifyAssignedPage({
    super.key,
    required this.salesmanId,
    required this.salesmanName,
    required this.currentShops,
  });

  @override
  State<ModifyAssignedPage> createState() => _ModifyAssignedPageState();
}

class _ModifyAssignedPageState extends State<ModifyAssignedPage> {
  List<dynamic> allShops = [];
  List<String> selectedShopIds = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();

    selectedShopIds = widget.currentShops
        .map<String>((e) => e["shop_id"]?.toString() ?? "")
        .where((e) => e.isNotEmpty)
        .toList();

    loadShops();
  }

  // --------------------------------------------------
  // LOAD ALL APPROVED SHOPS
  // --------------------------------------------------
  Future<void> loadShops() async {
    setState(() => loading = true);

    try {
      final shops = await api.ApiService.getShops();

      // only approved shops
      allShops = shops
          .where((s) => s["isApproved"] == true)
          .toList();
    } catch (e) {
      print("❌ Load shops error: $e");
      allShops = [];
    }

    setState(() => loading = false);
  }

  // --------------------------------------------------
  // SAVE CHANGES (RESET + ASSIGN)
  // --------------------------------------------------
  Future<void> saveChanges() async {
    final selectedShops = allShops
        .where((s) =>
            selectedShopIds.contains(
              s["shop_id"]?.toString(),
            ))
        .map((s) => {
              "shop_name": s["shop_name"],
              "address": s["address"],
              "segment": s["segment"],
            })
        .toList();

    final ok = await api.ApiService.resetAndAssign(
      widget.salesmanId,
      widget.salesmanName,
      selectedShops,
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Assigned Shops Updated Successfully"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Update Failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --------------------------------------------------
  // UI
  // --------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF007BFF), Color(0xFF66B2FF), Color(0xFFB8E0FF)],
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
                        color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Modify Assigned Shops",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: allShops.length,
                                itemBuilder: (_, i) {
                                  final shop = allShops[i];

                                  final shopId =
                                      shop["shop_id"]?.toString() ?? "";
                                  final shopName =
                                      shop["shop_name"] ?? "";
                                  final address =
                                      shop["address"] ?? "";

                                  final isSelected =
                                      selectedShopIds.contains(shopId);

                                  return Card(
                                    elevation: 3,
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    child: CheckboxListTile(
                                      value: isSelected,
                                      activeColor: Colors.blue,
                                      title: Text(
                                        shopName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(address),
                                      onChanged: (v) {
                                        setState(() {
                                          if (v == true) {
                                            selectedShopIds.add(shopId);
                                          } else {
                                            selectedShopIds.remove(shopId);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: saveChanges,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  backgroundColor: Colors.blueAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
    );
  }
}
