import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/location.dart';

class AttendanceBottomSheet extends StatefulWidget {
  final Map<String, dynamic> user;
  const AttendanceBottomSheet({super.key, required this.user});

  @override
  State<AttendanceBottomSheet> createState() => _AttendanceBottomSheetState();
}

class _AttendanceBottomSheetState extends State<AttendanceBottomSheet> {
  bool checkingIn = false;
  bool checkingOut = false;

  void _showMsg(String msg) {
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _doCheckIn() async {
    if (checkingIn) return;
    setState(() => checkingIn = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (pos == null) {
        _showMsg("Please turn ON Location.");
        return;
      }
      final res = await AttendanceService().checkIn(
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (!mounted) return;
      if (res["ok"] == true) {
        _showMsg("Checked In Successfully!");
      } else if (res["error"] == "already_checked_in") {
        _showMsg("You have already checked in today.");
      } else if (res["error"] == "outside_all_locations") {
        _showMsg("You are not in an allowed office location.");
      } else {
        _showMsg("Check-In Failed.");
      }
    } catch (e) {
      _showMsg(e.toString());
    } finally {
      if (mounted) setState(() => checkingIn = false);
    }
  }

  Future<void> _doCheckOut() async {
    if (checkingOut) return;
    setState(() => checkingOut = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (pos == null) {
        _showMsg("Please turn ON Location & allow permission.");
        return;
      }
      final res = await AttendanceService().checkOut(
        lat: pos.latitude,
        lng: pos.longitude,
      );
      if (!mounted) return;
      if (res["ok"] == true) {
        _showMsg("Checked Out Successfully!");
      } else if (res["error"] == "no_checkin_found") {
        _showMsg("You have not checked in today.");
      } else if (res["error"] == "already_checked_out") {
        _showMsg("You have already checked out today.");
      } else if (res["error"] == "checkout_window_closed") {
        _showMsg("Checkout time exceeded. Contact admin.");
      } else if (res["error"] == "outside_all_locations") {
        _showMsg("You are not in an allowed office location.");
      } else {
        _showMsg("Check-Out Failed. Try again.");
      }
    } catch (e) {
      _showMsg(e.toString());
    } finally {
      if (mounted) setState(() => checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name =
        (widget.user["name"] ?? widget.user["Name"] ?? widget.user["uid"] ?? "")
            .toString();
    final segment = (widget.user["segment"] ?? "").toString().toUpperCase();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "U";

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE3ECF7),
                child: Text(initial,
                    style: const TextStyle(
                        color: Color(0xFF002D62),
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                  if (segment.isNotEmpty)
                    Text(segment,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Attendance",
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF002D62))),
          const SizedBox(height: 4),
          const Text("Mark your attendance for today",
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: checkingIn ? null : _doCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: checkingIn
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Check In",
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: checkingOut ? null : _doCheckOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: checkingOut
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text("Check Out",
                          style: TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
