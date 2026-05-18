// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ShopsOutstandingPage extends StatefulWidget {
  const ShopsOutstandingPage({super.key});

  @override
  State<ShopsOutstandingPage> createState() => _ShopsOutstandingPageState();
}

class _ShopsOutstandingPageState extends State<ShopsOutstandingPage> {
  static const Color darkBlue = Color(0xFF002D62);

  List<dynamic> shops = [];
  Map<String, dynamic> summary = {};
  bool isLoading = true;
  String searchText = "";
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    final data = await ApiService.getShopsOutstanding();
    setState(() {
      shops = data["shops"] ?? [];
      summary = data["summary"] ?? {};
      isLoading = false;
    });
  }

  List<dynamic> get filteredShops {
    if (searchText.isEmpty) return shops;
    return shops
        .where((s) => (s["shop_name"] ?? "")
            .toString()
            .toLowerCase()
            .contains(searchText.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Shop Outstanding",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: darkBlue,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummarySection(),
                _buildSearchBar(),
                Expanded(child: _buildShopList()),
              ],
            ),
    );
  }

  // ── Summary Section ────────────────────────────────────
  Widget _buildSummarySection() {
    final totalBilled = summary["total_billed"] ?? 0;
    final totalOutstanding = summary["total_outstanding"] ?? 0;
    final matched = summary["matched_shops"] ?? 0;
    final unmatched = summary["unmatched_shops"] ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Big cards
          Row(
            children: [
              Expanded(
                child: _bigCard(
                  "Total Billed",
                  "₹${_formatAmount(totalBilled)}",
                  Icons.receipt_long,
                  Colors.indigo,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigCard(
                  "Outstanding",
                  "₹${_formatAmount(totalOutstanding)}",
                  Icons.account_balance_wallet,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Small chips
          Row(
            children: [
              _chip("✅ Matched: $matched", Colors.green),
              const SizedBox(width: 8),
              _chip("❌ Unmatched: $unmatched", Colors.orange),
              const SizedBox(width: 8),
              _chip(
                "🏪 Total: ${summary["total_shops"] ?? 0}",
                Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bigCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Search Bar ─────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: "Search shop name...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = "");
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) => setState(() => searchText = val),
      ),
    );
  }

  // ── Shop List ──────────────────────────────────────────
  Widget _buildShopList() {
    final list = filteredShops;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              "No shops found",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: loadData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildShopCard(list[i]),
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final bool matched = shop["matched"] == true;
    final double outstanding = (shop["outstanding"] ?? 0).toDouble();
    final double totalBilled = (shop["total_billed"] ?? 0).toDouble();

    // Color based on outstanding amount
    Color outstandingColor = Colors.green;
    if (outstanding > 100000) outstandingColor = Colors.red;
    else if (outstanding > 50000) outstandingColor = Colors.orange;
    else if (outstanding > 0) outstandingColor = Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop name + match badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop["shop_name"] ?? "-",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: matched
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    matched ? "✅ Matched" : "❌ No Match",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: matched ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),

            if (matched && shop["zoho_name"] != null) ...[
              const SizedBox(height: 4),
              Text(
                "Zoho: ${shop["zoho_name"]}",
                style:
                    const TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Amount row
            Row(
              children: [
                Expanded(
                  child: _amountTile(
                    "Total Billed",
                    "₹${_formatAmount(totalBilled)}",
                    Colors.indigo,
                  ),
                ),
                Expanded(
                  child: _amountTile(
                    "Outstanding",
                    "₹${_formatAmount(outstanding)}",
                    outstandingColor,
                  ),
                ),
                Expanded(
                  child: _amountTile(
                    "Invoices",
                    "${shop["invoice_count"] ?? 0}",
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountTile(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    final double val = (amount ?? 0).toDouble();
    if (val >= 100000) return "${(val / 100000).toStringAsFixed(1)}L";
    if (val >= 1000) return "${(val / 1000).toStringAsFixed(1)}K";
    return val.toStringAsFixed(0);
  }
}