// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'log_history_page.dart';
import 'attendance_bottom_sheet.dart';
import 'add_location_page.dart';

class LogHistoryFilterPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const LogHistoryFilterPage({super.key, required this.user});

  @override
  State<LogHistoryFilterPage> createState() => _LogHistoryFilterPageState();
}

class _LogHistoryFilterPageState extends State<LogHistoryFilterPage> {
  String resultFilter = "All";
  String segmentFilter = "All";

  DateTime? startDate;
  DateTime? endDate;

  late List<String> segmentOptions;
  final resultOptions = ["All", "Match", "Mismatch"];

  @override
  void initState() {
    super.initState();

    final role = widget.user["role"].toString().toLowerCase();
    final segment = widget.user["segment"].toString().toUpperCase();

    // ✅ SEGMENT OPTIONS LOGIC (UNCHANGED)
    if (role == "manager") {
      segmentOptions = ["All", segment];
    } else if (role == "salesman") {
      segmentOptions = [segment];
      segmentFilter = segment;
    } else {
      segmentOptions = ["All", "FMCG", "PIPES"];
    }
  }

  // ----------------- ATTENDANCE SHEET -----------------
  void _showAttendanceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AttendanceBottomSheet(user: widget.user),
    );
  }

  // ----------------- DATE PICKERS -----------------
  Future<void> pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => startDate = d);
  }

  Future<void> pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => endDate = d);
  }

  // ----------------- APPLY FILTERS -----------------
  void applyFilters() {
    // ✅ RESULT MAPPING LOGIC (UNCHANGED)
    String resultMapped = resultFilter == "All"
        ? "All"
        : (resultFilter == "Match" ? "match" : "mismatch");

    // ✅ DATE RANGE VALIDATION (UNCHANGED)
    if (startDate != null && endDate != null) {
      if (endDate!.isBefore(startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("End date cannot be before Start date")),
        );
        return;
      }
    }

    // ✅ NAVIGATION (UNCHANGED)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogHistoryPage(
          user: widget.user,
          segment: segmentFilter.toUpperCase(),
          result: resultMapped,
          startDate: startDate,
          endDate: endDate,
        ),
      ),
    );
  }

  // ================= UI BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // ✅ CURVED HEADER BACKGROUND
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

          // ✅ MAIN CONTENT FLOATING CARD
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ✅ PAGE TITLE INSIDE HEADER
                  const Text(
                    "Filter Logs",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Choose segment, result & date range",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ✅ FLOATING FILTER CARD
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
                          // ✅ SEGMENT DROPDOWN
                          DropdownButtonFormField(
                            decoration: inputDecor("Segment"),
                            value: segmentFilter,
                            items: segmentOptions
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => segmentFilter = v!),
                          ),

                          const SizedBox(height: 18),

                          // ✅ RESULT DROPDOWN
                          DropdownButtonFormField(
                            decoration: inputDecor("Result"),
                            value: resultFilter,
                            items: resultOptions
                                .map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => resultFilter = v!),
                          ),

                          const SizedBox(height: 22),

                          // ✅ DATE BUTTONS
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: pickStart,
                                  icon: const Icon(Icons.calendar_month,
                                      size: 18),
                                  style: dateBtn(),
                                  label: Text(
                                    startDate == null
                                        ? "Start Date"
                                        : "${startDate!.day}-${startDate!.month}-${startDate!.year}",
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: pickEnd,
                                  icon: const Icon(Icons.calendar_month,
                                      size: 18),
                                  style: dateBtn(),
                                  label: Text(
                                    endDate == null
                                        ? "End Date"
                                        : "${endDate!.day}-${endDate!.month}-${endDate!.year}",
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const Spacer(),

                          // ✅ APPLY BUTTON
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF002D62),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Show Logs",
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          const Divider(height: 24, color: Color(0xFFF0F0F0)),

                          _bottomActions(),
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

  // ---------- INPUT DECOR ----------
  InputDecoration inputDecor(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF002D62)),
      filled: true,
      fillColor: const Color(0xFFF4F7FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  // ---------- DATE BUTTON ----------
  ButtonStyle dateBtn() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFE3ECF7),
      foregroundColor: Colors.black87,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  // ================= UI BUILD =====================

// ----------------- BOTTOM SHEET BUTTONS -----------------
  Widget _bottomActions() {
    final role = widget.user["role"].toString().toLowerCase();

    if (role == "master") {
      // ✅ MASTER - Location Add button
      return Align(
        alignment: Alignment.centerRight,
        child: TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddLocationPage(user: widget.user),
              ),
            );
          },
          icon: const Icon(Icons.add_location_alt,
              size: 20, color: Color(0xFF002D62)),
          label: const Text(
            "Add Location",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF002D62),
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFE8F0FA),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      );
    }

    // ✅ SALESMAN / MANAGER - Attendance button
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: _showAttendanceSheet,
        icon: const Icon(Icons.fingerprint, size: 20, color: Color(0xFF002D62)),
        label: const Text(
          "Attendance",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF002D62),
          ),
        ),
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFE8F0FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      ),
    );
  }
}
