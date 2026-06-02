// ignore_for_file: avoid_print, deprecated_member_use, unused_local_variable, use_build_context_synchronously, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'full_network_image_page.dart';
import 'map_route_page.dart';
import 'dart:convert';

class LogHistoryPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String segment;
  final String result;
  final DateTime? startDate;
  final DateTime? endDate;

  const LogHistoryPage({
    super.key,
    required this.user,
    required this.segment,
    required this.result,
    this.startDate,
    this.endDate,
  });

  @override
  State<LogHistoryPage> createState() => _LogHistoryPageState();
}

class _LogHistoryPageState extends State<LogHistoryPage> {
  List<dynamic> logs = [];
  bool loading = true;
  String search = "";

  @override
  void initState() {
    super.initState();
    loadLogs();
  }

  // ---------------- LOAD LOGS ---------------- //
  Future<void> loadLogs() async {
    if (!mounted) return;
    setState(() => loading = true);

    final role = widget.user["role"].toString().toLowerCase();
    final userName = widget.user["name"].toString();
    final userSegment = widget.user["segment"].toString();

    print("👤 ROLE => $role");
    print("👤 USER NAME => $userName");
    print("👤 USER SEGMENT => $userSegment");

    // ******** GET FROM VisitLog API ******** //
    final rawResponse = await ApiService.getLogs(); // ← List இல்லாம Map வரும்

    // Safely parse visits
    final visitsRaw = rawResponse["visits"];
    final List<dynamic> rawVisits = visitsRaw is String
        ? jsonDecode(visitsRaw)
        : (visitsRaw as List<dynamic>? ?? []);

// Safely parse zoho_sales
    final salesRaw = rawResponse["zoho_sales"];
    final List<dynamic> zohoSales = salesRaw is String
        ? jsonDecode(salesRaw)
        : (salesRaw as List<dynamic>? ?? []);

// zoho_sales-ஐ visitId வச்சு map பண்ணு
    final Map<String, dynamic> zohoMap = {};
    for (var z in zohoSales) {
      zohoMap[z["visitId"]] = z["sales"];
    }

    print("✅ RAW LOG COUNT => ${rawVisits.length}");
    if (rawVisits.isNotEmpty) {
      print("✅ RAW FIRST ITEM => ${rawVisits[0]}");
    }

// ******** MAP TO APP FORMAT (USING VISITLOG) ******** //
    List<dynamic> all = rawVisits.map((l) {
      DateTime dt;
      bool isCall = (l["durationSec"] ?? 0) > 0;

      try {
        dt = DateTime.parse(l["createdAt"]).toLocal();
      } catch (e) {
        dt = DateTime.now();
      }

      // zoho_sales match பண்ணு
      final zoho = zohoMap[l["visit_id"]];

      return {
        "pk": l["pk"],
        "sk": l["sk"],
        "shopName": l["shop_name"] ?? "",
        "salesman": l["salesmanName"] ??
            (widget.user["role"].toString().toLowerCase() == "salesman"
                ? widget.user["name"]
                : l["salesmanName"] ?? ""),
        "photoUrl": l["photo_url"] ?? "",
        "result": isCall ? null : l["result"] == "match",
        "isCall": isCall,
        "lat":
            l["shopLat"] != null ? double.tryParse(l["lat"].toString()) : null,
        "lng":
            l["shopLng"] != null ? double.tryParse(l["lng"].toString()) : null,
        "distance": double.tryParse(l["distance"].toString()) ?? 0.0,
        "date": DateFormat("dd-MM-yyyy").format(dt),
        "time": DateFormat("hh:mm a").format(dt).toUpperCase(),
        "segment": l["segment"] ?? "",
        "duration": (l["durationSec"] != null)
            ? (l["durationSec"] as num).toDouble()
            : 0.0,
        // ✅ zoho_sales attach
        "zoho_sales": zoho != null
            ? {
                "total_sales": zoho["total_sales"],
                "invoice_count": zoho["invoice_count"],
                "invoices": (zoho["invoices"] as List? ?? []),
              }
            : null,
      };
    }).toList();

    print("✅ AFTER MAP COUNT => ${all.length}");
    if (all.isNotEmpty) {
      print("✅ MAPPED FIRST SALESMAN => ${all[0]["salesman"]}");
    }

    // --------------------------------------------------------------------
    // ROLE BASED FILTERING
    // --------------------------------------------------------------------
    List<dynamic> filtered = all;

    if (role == "salesman") {
      filtered = filtered.where((l) {
        return l["salesman"]
            .toString()
            .toLowerCase()
            .contains(userName.toLowerCase());
      }).toList();

      print("✅ AFTER SALESMAN FILTER => ${filtered.length}");
    }

    if (role == "manager") {
      filtered = filtered
          .where((l) =>
              l["segment"].toString().toUpperCase() ==
              userSegment.toUpperCase())
          .toList();

      print("✅ AFTER MANAGER FILTER => ${filtered.length}");
    }

    // --------------------------------------------------------------------
    // FILTER BY SEGMENT (from filter screen)
    // --------------------------------------------------------------------
    if (widget.segment != "All") {
      filtered = filtered
          .where((l) =>
              l["segment"].toString().toUpperCase() ==
              widget.segment.toUpperCase())
          .toList();

      print("✅ AFTER SEGMENT FILTER => ${filtered.length}");
    }

    // --------------------------------------------------------------------
    // FILTER BY RESULT (match/mismatch)
    // --------------------------------------------------------------------
    if (widget.result != "All") {
      bool wantMatch = widget.result.toLowerCase() == "match";
      filtered = filtered.where((l) => l["result"] == wantMatch).toList();

      print("✅ AFTER RESULT FILTER => ${filtered.length}");
    }

    // --------------------------------------------------------------------
    // FILTER BY DATE RANGE
    // --------------------------------------------------------------------
    if (widget.startDate != null || widget.endDate != null) {
      filtered = filtered.where((l) {
        if (l["date"] == "") return false;

        DateTime dt = DateFormat("dd-MM-yyyy").parse(l["date"]);

        if (widget.startDate != null && dt.isBefore(widget.startDate!)) {
          return false;
        }
        if (widget.endDate != null && dt.isAfter(widget.endDate!)) {
          return false;
        }

        return true;
      }).toList();

      print("✅ AFTER DATE FILTER => ${filtered.length}");
    }

    logs = filtered;

    print("📌 FINAL LOGS COUNT => ${logs.length}");

    if (!mounted) return;
    setState(() => loading = false);
  }

  // --------------------------------------------------------------------
  // Formatting duration from seconds to "X mins" or "Y sec"
  // --------------------------------------------------------------------
  String formatDuration(double seconds) {
    if (seconds < 60) {
      return "${seconds.toStringAsFixed(0)} sec";
    } else {
      double mins = seconds / 60;
      return "${mins.toStringAsFixed(2)} mins";
    }
  }

  Future<void> confirmDelete(dynamic log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Visit"),
        content: const Text("Are you sure you want to hide this visit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      bool success = await ApiService.deleteVisit(log["pk"], log["sk"]);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(14),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Visit hidden successfully",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        loadLogs(); // 🔄 Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            margin: const EdgeInsets.all(14),
            content: Row(
              children: const [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Delete failed",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
  // --------------------------------------------------------------------
  // UI STARTS
  // --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final matched =
        logs.where((l) => l["isCall"] == false && l["result"] == true).length;

    final mismatched =
        logs.where((l) => l["isCall"] == false && l["result"] == false).length;
    final totalDuration = logs.fold<double>(
      0,
      (sum, l) => sum + ((l["duration"] ?? 0) as num).toDouble(),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // ✅ PREMIUM CURVED HEADER
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

                  // ✅ HEADER ROW (BACK + REFRESH)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        "Log History",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),

                      // ✅ NEW — Map Route button
                      IconButton(
                        icon: const Icon(Icons.map_outlined,
                            color: Colors.white, size: 26),
                        tooltip: "Route Map",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MapRoutePage(
                                user: widget.user,
                              ),
                            ),
                          );
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.refresh,
                            color: Colors.white, size: 26),
                        onPressed: loadLogs,
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Matches & mismatches overview",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
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
                      // 🔥 TOTAL DURATION SUMMARY

                      child: Column(
                        children: [
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3ECF7),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Call Duration",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  formatDuration(totalDuration),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 🔍 PREMIUM SEARCH BAR
                          buildSearchBar(),

                          const SizedBox(height: 20),

                          // ✅ LOG LIST
                          Expanded(child: buildList()),
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

  Widget buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => search = v),
      decoration: InputDecoration(
        hintText: "Search shop...",
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: const Color(0xFFF4F7FC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget buildList() {
    if (loading) return const Center(child: CircularProgressIndicator());

    final result = logs.where((l) {
      return l["shopName"].toLowerCase().contains(search.toLowerCase());
    }).toList();

    if (result.isEmpty) return const Center(child: Text("No logs found"));

    return ListView.builder(
      itemCount: result.length,
      itemBuilder: (_, i) {
        final log = result[i];
        final isCall = log["isCall"] == true;
        final isMatch = log["result"] == true;

        String label;
        Color color;

        if (isCall) {
          label = "CALL";
          color = Colors.orange;
        } else if (isMatch) {
          label = "MATCH";
          color = Colors.green;
        } else {
          label = "MISMATCH";
          color = Colors.red;
        }
        final role = widget.user["role"].toString().toLowerCase();
        final canDelete = role == "master" || role == "manager";
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: Colors.blue.withOpacity(0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullNetworkImagePage(
                        imageUrl: log["photoUrl"],
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFF4F7FC),
                  backgroundImage: log["photoUrl"] != ""
                      ? NetworkImage(log["photoUrl"])
                      : null,
                  child: log["photoUrl"] == ""
                      ? const Icon(Icons.photo, color: Colors.black54)
                      : null,
                ),
              ),

              const SizedBox(width: 12),

              // CONTENT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔥 SHOP NAME + DELETE
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log["shopName"],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (canDelete)
                          InkWell(
                            onTap: () => confirmDelete(log),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // MATCH / MISMATCH / CALL
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // DATE
                    Text(
                      "${log["date"]} @ ${log["time"]}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // SALESMAN + DISTANCE
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Salesman: ${log["salesman"]}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${log["distance"].toStringAsFixed(1)} m",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Color(0xFF002D62),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // CALL DURATION
                    if (isCall) ...[
                      const SizedBox(height: 6),
                      Text(
                        "Duration: ${formatDuration((log["duration"] ?? 0).toDouble())}",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                    // CALL DURATION block-க்கு கீழே add பண்ணுங்க
                    // ✅ இப்படி மாத்து — mismatch-க்கு காட்டாது
                    if (log["zoho_sales"] != null &&
                        log["result"] == true && // ← MATCH மட்டும்
                        widget.user["role"].toString().toLowerCase() ==
                            "master") ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "🧾 Zoho Sales",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  "₹${log["zoho_sales"]["total_sales"]}",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.green, thickness: 0.5),
                            // EACH INVOICE
                            ...List.generate(
                              ((log["zoho_sales"]["invoices"] ?? []) as List)
                                  .length,
                              (i) {
                                final inv = log["zoho_sales"]["invoices"][i];
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "Invoice ${i + 1}  ${inv["invoice_date"] ?? inv["date"] ?? ""}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        "₹${inv["total"]}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
