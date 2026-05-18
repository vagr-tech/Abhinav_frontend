// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SalesOrdersPage extends StatefulWidget {
  const SalesOrdersPage({super.key});

  @override
  State<SalesOrdersPage> createState() => _SalesOrdersPageState();
}

class _SalesOrdersPageState extends State<SalesOrdersPage> {
  // ── State ──────────────────────────────────────────────
  List<dynamic> orders = [];
  Map<String, dynamic> summary = {};
  Map<String, dynamic> pagination = {};

  bool isLoading = true;
  String selectedStatus = "all";
  String searchText = "";

  final TextEditingController searchController = TextEditingController();

  // Status filter options — backend-ல் வரும் values
  final List<Map<String, String>> statusFilters = [
    {"label": "All", "value": "all"},
    {"label": "Draft", "value": "draft"},
    {"label": "Open", "value": "open"},
    {"label": "Invoiced", "value": "invoiced"},
    {"label": "Partial", "value": "partially_invoiced"},
    {"label": "Closed", "value": "closed"},
  ];

  // Status color map
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "draft":
        return Colors.grey;
      case "open":
        return Colors.blue;
      case "invoiced":
        return Colors.green;
      case "partially_invoiced":
        return Colors.orange;
      case "closed":
        return Colors.red;
      default:
        return Colors.purple;
    }
  }

  // ── Load Data ──────────────────────────────────────────
  Future<void> loadOrders() async {
    setState(() => isLoading = true);

    final data = await ApiService.getSalesOrders(
      status: selectedStatus == "all" ? null : selectedStatus,
      search: searchText.isEmpty ? null : searchText,
    );

    setState(() {
      orders = data["orders"] ?? [];
      summary = data["summary"] ?? {};
      pagination = data["pagination"] ?? {};
      isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          "Sales Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Summary Cards ──────────────────────────────
          _buildSummaryCards(),

          // ── Search Bar ────────────────────────────────
          _buildSearchBar(),

          // ── Status Filter Chips ───────────────────────
          _buildStatusFilters(),

          // ── Order List ────────────────────────────────
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrderList(),
          ),
        ],
      ),
    );
  }

  // ── Summary Cards ──────────────────────────────────────
  Widget _buildSummaryCards() {
    final total = pagination["total"] ?? orders.length;
    final invoiced = summary["invoiced"] ?? 0;
    final draft = summary["draft"] ?? 0;
    final partial = summary["partially_invoiced"] ?? 0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          _summaryCard("Total", total.toString(), Colors.indigo),
          const SizedBox(width: 8),
          _summaryCard("Invoiced", invoiced.toString(), Colors.green),
          const SizedBox(width: 8),
          _summaryCard("Draft", draft.toString(), Colors.grey),
          const SizedBox(width: 8),
          _summaryCard("Partial", partial.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              count,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
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
          hintText: "Search by shop name...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchText = "");
                    loadOrders();
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
        onChanged: (val) {
          setState(() => searchText = val);
          // 500ms debounce
          Future.delayed(const Duration(milliseconds: 500), () {
            if (searchText == val) loadOrders();
          });
        },
      ),
    );
  }

  // ── Status Filter Chips ────────────────────────────────
  Widget _buildStatusFilters() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: statusFilters.length,
        itemBuilder: (context, index) {
          final filter = statusFilters[index];
          final isSelected = selectedStatus == filter["value"];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter["label"]!),
              selected: isSelected,
              onSelected: (_) {
                setState(() => selectedStatus = filter["value"]!);
                loadOrders();
              },
              selectedColor: Colors.indigo.withOpacity(0.2),
              checkmarkColor: Colors.indigo,
              labelStyle: TextStyle(
                color: isSelected ? Colors.indigo : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Order List ─────────────────────────────────────────
  Widget _buildOrderList() {
    return RefreshIndicator(
      onRefresh: loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order["status"] ?? "unknown";
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status indicator
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            // Order details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order["salesorder_number"] ?? "-",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order["customer_name"] ?? "-",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order["date"] ?? "-",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        "₹${order["total"]?.toString() ?? "0"}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No orders found",
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          if (searchText.isNotEmpty || selectedStatus != "all") ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                searchController.clear();
                setState(() {
                  searchText = "";
                  selectedStatus = "all";
                });
                loadOrders();
              },
              child: const Text("Clear filters"),
            ),
          ],
        ],
      ),
    );
  }
}