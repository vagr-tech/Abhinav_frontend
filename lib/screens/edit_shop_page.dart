// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditShopPage extends StatefulWidget {
  final Map shop;

  const EditShopPage({super.key, required this.shop});

  @override
  State<EditShopPage> createState() => _EditShopPageState();
}

class _EditShopPageState extends State<EditShopPage> {
  late TextEditingController nameCtrl;
  late TextEditingController addrCtrl;
  late TextEditingController gstCtrl;
  late TextEditingController primaryPhoneCtrl;
  late TextEditingController secondaryPhoneCtrl;

  String segment = "";

  @override
  void initState() {
    super.initState();

    nameCtrl = TextEditingController(
        text: widget.shop["shopName"] ?? widget.shop["shop_name"]);
    addrCtrl = TextEditingController(
        text: widget.shop["shopAddress"] ?? widget.shop["address"]);
    gstCtrl = TextEditingController(
        text: widget.shop["gstNumber"] ?? widget.shop["gst_number"] ?? "");
    primaryPhoneCtrl = TextEditingController(
        text:
            widget.shop["primaryPhone"] ?? widget.shop["primary_phone"] ?? "");
    secondaryPhoneCtrl = TextEditingController(
        text: widget.shop["secondaryPhone"] ??
            widget.shop["secondary_phone"] ??
            "");
    segment = (widget.shop["segment"] ?? "fmcg").toString().toUpperCase();
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    addrCtrl.dispose();
    gstCtrl.dispose();
    primaryPhoneCtrl.dispose();
    secondaryPhoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // curved header
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Edit Shop",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.only(left: 48),
                    child: Text(
                      "Update shop details below",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
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
                      child: ListView(
                        children: [
                          const SizedBox(height: 6),

                          // GST Number
                          TextField(
                            controller: gstCtrl,
                            decoration: inputDecor("GST Number (Optional)"),
                          ),
                          const SizedBox(height: 18),

                          // Shop Name
                          TextField(
                            controller: nameCtrl,
                            decoration: inputDecor("Shop Name"),
                          ),
                          const SizedBox(height: 18),

                          // Address
                          TextField(
                            controller: addrCtrl,
                            decoration: inputDecor("Address"),
                          ),
                          const SizedBox(height: 18),

                          // Primary Phone
                          TextField(
                            controller: primaryPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: inputDecor("Primary Phone"),
                          ),
                          const SizedBox(height: 18),

                          // Secondary Phone
                          TextField(
                            controller: secondaryPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration:
                                inputDecor("Secondary Phone (Optional)"),
                          ),
                          const SizedBox(height: 18),

                          // Segment
                          DropdownButtonFormField<String>(
                            value: segment,
                            decoration: inputDecor("Select Segment"),
                            items: ["FMCG", "PIPES"]
                                .map((s) =>
                                    DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => segment = v.toString()),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: saveShop,
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 20, color: Colors.white),
                              label: const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                                shadowColor: Colors.black26,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),
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

  Future<void> saveShop() async {
    if (nameCtrl.text.trim().isEmpty) {
      _error("Enter shop name");
      return;
    }
    if (addrCtrl.text.trim().isEmpty) {
      _error("Enter address");
      return;
    }
    if (primaryPhoneCtrl.text.trim().isEmpty) {
      _error("Enter primary phone");
      return;
    }

    final updated = {
      "shop_id": widget.shop["shop_id"],
      "shop_name": nameCtrl.text.trim(),
      "address": addrCtrl.text.trim(),
      "segment": segment.toLowerCase(),
      "gstNumber": gstCtrl.text.trim(),
      "primaryPhone": primaryPhoneCtrl.text.trim(),
      "secondaryPhone": secondaryPhoneCtrl.text.trim(),
    };

    final ok = await ApiService.updateShop(updated);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shop updated successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 800));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Shop update failed"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }
}

InputDecoration inputDecor(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF002D62)),
    filled: true,
    fillColor: const Color(0xFFF4F7FC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      borderSide: const BorderSide(color: Color(0xFF005BBB), width: 1.5),
    ),
  );
}
