// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const DashboardPage({super.key, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool loading = true;
  Map<String, dynamic>? data;
  Map<String, dynamic>? attendanceData; // ✅ NEW
  int _selectedTab = 0; // ✅ NEW - 0: Visit, 1: Attendance

  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  static const Color darkBlue = Color(0xFF002D62);

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final startStr =
        "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";
    final endStr =
        "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}";

    if (_selectedTab == 0) {
      final result = await ApiService.getDashboardReport(startStr, endStr);
      if (mounted) {
        setState(() {
          data = result;
          loading = false;
        });
      }
    } else {
      final result = await ApiService.getAttendanceReport(startStr, endStr);
      if (mounted) {
        setState(() {
          attendanceData = result;
          loading = false;
        });
      }
    }
  }

  String formattime(String time) {
    try {
      final inputFormat = DateFormat("dd/MM/yyyy, hh:mm:ss a");
      final outputFormat = DateFormat("h:mm a");

      final dt = inputFormat.parse(time.toUpperCase());
      return outputFormat.format(dt);
    } catch (e) {
      return time; // fallback
    }
  }

  String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m ${secs}s";
    } else {
      return "${secs}s";
    }
  }

  String formatTime(String time) {
    try {
      final dt = DateTime.parse(time).toLocal();
      int hour = dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      String period = hour >= 12 ? "PM" : "AM";
      hour = hour % 12;
      if (hour == 0) hour = 12;
      return "$hour:$minute $period";
    } catch (_) {
      return time;
    }
  }

  Future<void> pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => startDate = picked);
  }

  Future<void> pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => endDate = picked);
  }

  Widget quickChip(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF002D62), Color(0xFF005BBB)],
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
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Performance overview",
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),

                  // ✅ DATE PICKERS
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickStartDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                              "${startDate.day}-${startDate.month}-${startDate.year}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: darkBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: pickEndDate,
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: Text(
                              "${endDate.day}-${endDate.month}-${endDate.year}"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: darkBlue,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: loadData,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ✅ QUICK CHIPS
                  Row(
                    children: [
                      quickChip("Today", () {
                        setState(() {
                          startDate = DateTime.now();
                          endDate = DateTime.now();
                        });
                        loadData();
                      }),
                      const SizedBox(width: 8),
                      quickChip("7 Days", () {
                        setState(() {
                          startDate =
                              DateTime.now().subtract(const Duration(days: 7));
                          endDate = DateTime.now();
                        });
                        loadData();
                      }),
                      const SizedBox(width: 8),
                      quickChip("This Month", () {
                        final now = DateTime.now();
                        setState(() {
                          startDate = DateTime(now.year, now.month, 1);
                          endDate = now;
                        });
                        loadData();
                      }),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ✅ TAB BUTTONS
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedTab = 0);
                              loadData();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 0
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  "Visit Report",
                                  style: TextStyle(
                                    color: _selectedTab == 0
                                        ? darkBlue
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedTab = 1);
                              loadData();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 9),
                              decoration: BoxDecoration(
                                color: _selectedTab == 1
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(
                                  "Attendance",
                                  style: TextStyle(
                                    color: _selectedTab == 1
                                        ? darkBlue
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ✅ CONTENT
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : _selectedTab == 0
                            ? Column(children: [
                                buildSummaryCards(),
                                const SizedBox(height: 12),
                                Expanded(child: buildSalesmanList()),
                              ])
                            : buildAttendanceList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── VISIT REPORT WIDGETS (UNCHANGED) ───────────────────

  Widget buildSummaryCards() {
    final visits = data?["totalVisits"] ?? 0;
    final calls = data?["totalCalls"] ?? 0;
    final match = data?["totalMatch"] ?? 0;
    final mismatch = data?["totalMismatch"] ?? 0;

    return Row(
      children: [
        Expanded(
            child: summaryMini(Icons.store, "Visits", visits, Colors.blue)),
        const SizedBox(width: 6),
        Expanded(
            child: summaryMini(Icons.phone, "Calls", calls, Colors.orange)),
        const SizedBox(width: 6),
        Expanded(
            child:
                summaryMini(Icons.check_circle, "Match", match, Colors.green)),
        const SizedBox(width: 6),
        Expanded(
            child: summaryMini(Icons.cancel, "Mismatch", mismatch, Colors.red)),
      ],
    );
  }

  Widget summaryMini(IconData icon, String title, int value, Color color) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 14),
            ),
            const SizedBox(height: 4),
            Text(value.toString(),
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(fontSize: 10, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget summaryItem(IconData icon, String title, int value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value.toString(),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ],
    );
  }

  Widget buildSalesmanList() {
    final list = data?["salesmanPerformance"] ?? [];

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final rep = list[i];
        final int duration = rep["callDuration"] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: darkBlue,
                    child: Text(rep["name"][0],
                        style: const TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(rep["name"],
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (rep["inTime"] != null)
                        Text("In ${formatTime(rep["inTime"])}",
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600)),
                      if (rep["inTime"] != null && rep["outTime"] != null)
                        const Text("  |  ", style: TextStyle(fontSize: 11)),
                      if (rep["outTime"] != null)
                        Text("Out ${formatTime(rep["outTime"])}",
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                    ],
                  )
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: stat("Visits", rep["visits"], Colors.blue)),
                  Expanded(child: stat("Calls", rep["calls"], Colors.orange)),
                  Expanded(child: stat("Match", rep["match"], Colors.green)),
                  Expanded(
                      child: stat("Mismatch", rep["mismatch"], Colors.red)),
                  Expanded(child: stat("Duration", duration, Colors.purple)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget stat(String title, int value, Color color) {
    String displayValue =
        title == "Duration" ? formatDuration(value) : value.toString();
    return Column(
      children: [
        Text(displayValue,
            style: TextStyle(
                fontSize: title == "Duration" ? 12 : 14,
                fontWeight: FontWeight.bold,
                color: color)),
        const SizedBox(height: 4),
        Text(title,
            style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }

  // ─── ATTENDANCE REPORT WIDGETS (NEW) ────────────────────

  Widget buildAttendanceList() {
    final list = attendanceData?["attendanceReport"] ?? [];
    final totalRecords = attendanceData?["totalRecords"] ?? 0;

    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fingerprint, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text("No attendance records found",
                style: TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ✅ SUMMARY CARD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              _attendanceSummaryTile(
                Icons.people,
                "Staff",
                "${list.length}",
                Colors.blue,
              ),
              _divider(),
              _attendanceSummaryTile(
                Icons.check_circle,
                "Present",
                "$totalRecords",
                Colors.green,
              ),
              _divider(),
              _attendanceSummaryTile(
                Icons.logout,
                "Checked Out",
                "${list.where((r) => (r["records"] as List? ?? []).any((rec) => rec["checkOutAt"] != null)).length}",
                Colors.orange,
              ),
              _divider(),
              _attendanceSummaryTile(
                Icons.warning_amber,
                "No Checkout",
                "${list.where((r) => (r["records"] as List? ?? []).any((rec) => rec["checkOutAt"] == null)).length}",
                Colors.red,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ✅ USER LIST
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final rep = list[i];
              final records = rep["records"] as List? ?? [];
              final totalDays = rep["totalDays"] ?? 0;

              // Latest record
              final latest = records.isNotEmpty ? records.last : null;
              final hasNoCheckout = records.any((r) => r["checkOutAt"] == null);

              return GestureDetector(
                onTap: () => _showAttendanceSheet(rep),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // ✅ Avatar
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: darkBlue,
                        child: Text(
                          rep["name"][0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ✅ Name + latest time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rep["name"],
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 3),
                            if (latest != null)
                              Row(
                                children: [
                                  if (latest["checkInAt"] != null) ...[
                                    const Icon(Icons.login,
                                        size: 11, color: Colors.green),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatIST(latest["checkInAt"]),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                  if (latest["checkOutAt"] != null) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.logout,
                                        size: 11, color: Colors.red),
                                    const SizedBox(width: 3),
                                    Text(
                                      _formatIST(latest["checkOutAt"]),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.red,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        ),
                      ),

                      // ✅ Right side badges
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "$totalDays ${totalDays == 1 ? 'Day' : 'Days'}",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF002D62),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (hasNoCheckout)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "No Checkout",
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(width: 6),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

// ✅ BOTTOM SHEET
  void _showAttendanceSheet(Map rep) {
    final records = rep["records"] as List? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: darkBlue,
                  child: Text(
                    rep["name"][0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Text(rep["name"],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${rep["totalDays"]} ${rep["totalDays"] == 1 ? 'Day' : 'Days'}",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF002D62),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100),
            const SizedBox(height: 8),

            // Records list
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: records.length,
                itemBuilder: (_, i) {
                  final r = records[i];
                  final hasCheckout = r["checkOutAt"] != null;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F7FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 13, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(r["date"] ?? "",
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: hasCheckout
                                    ? Colors.green.shade50
                                    : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hasCheckout ? "Complete" : "No Checkout",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: hasCheckout
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Check In
                        if (r["checkInAt"] != null)
                          _timeRow(
                            Icons.login,
                            "Check In",
                            _formatIST(r["checkInAt"]),
                            r["checkInLocation"] ?? "",
                            Colors.green,
                          ),

                        if (hasCheckout) const SizedBox(height: 6),

                        // Check Out
                        if (hasCheckout)
                          _timeRow(
                            Icons.logout,
                            "Check Out",
                            _formatIST(r["checkOutAt"]),
                            r["checkOutLocation"] ?? "",
                            Colors.red,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

// ✅ HELPER WIDGETS
  Widget _timeRow(
      IconData icon, String label, String time, String location, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            if (location.isNotEmpty)
              Text(location,
                  style: const TextStyle(fontSize: 10, color: Colors.black45)),
          ],
        ),
      ],
    );
  }

  Widget _attendanceSummaryTile(
      IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  String _formatIST(String raw) {
    try {
      // IST format: "30/04/2026, 12:09:54 pm"
      return raw.split(", ").last.toUpperCase();
    } catch (_) {
      return raw;
    }
  }
}
