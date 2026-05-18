// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class AddLocationPage extends StatefulWidget {
  final Map<String, dynamic> user;
  const AddLocationPage({super.key, required this.user});

  @override
  State<AddLocationPage> createState() => _AddLocationPageState();
}

class _AddLocationPageState extends State<AddLocationPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();

  bool _loading = false;
  bool _fetchingLocation = false;
  double? _lat;
  double? _lng;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  // ----------------- GET LOCATION -----------------
  Future<void> _getLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack("Location permission denied");
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      });
    } catch (e) {
      _showSnack("Location fetch failed");
    } finally {
      setState(() => _fetchingLocation = false);
    }
  }

  // ----------------- SUBMIT -----------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ✅ Location check
    if (_lat == null || _lng == null) {
      _showSnack("Please get current location first");
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ AuthService.token use பண்றோம்
      final token = AuthService.token;

      if (token == null) {
        _showSnack("Session expired, please login again");
        return;
      }

      final res = await http.post(
        Uri.parse("https://abhinav-backend.onrender.com/api/locations/add"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "name": _nameCtrl.text.trim(),
          "lat": _lat,
          "lng": _lng,
          "radius": int.parse(_radiusCtrl.text.trim()),
        }),
      );

      final data = jsonDecode(res.body);

      if (data["ok"] == true) {
        _showSnack("Location added successfully!", success: true);
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pop(context);
        });
      } else {
        _showSnack(data["error"] ?? "Something went wrong");
      }
    } catch (e) {
      _showSnack("Error: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // ✅ HEADER
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),

                  const SizedBox(height: 6),

                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      "Add Location",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                      "Add a new check-in location for your team",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ✅ FORM CARD
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
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
                      child: Form(
                        key: _formKey,
                        child: ListView(
                          children: [
                            // Name
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: inputDecor(
                                  "Location Name", Icons.location_city),
                              validator: (v) =>
                                  v!.isEmpty ? "Name required" : null,
                            ),

                            const SizedBox(height: 16),

                            // ✅ GET LOCATION BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed:
                                    _fetchingLocation ? null : _getLocation,
                                icon: _fetchingLocation
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF005BBB),
                                        ),
                                      )
                                    : const Icon(Icons.my_location,
                                        size: 20, color: Color(0xFF005BBB)),
                                label: Text(
                                  _fetchingLocation
                                      ? "Fetching..."
                                      : "Get Current Location",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF005BBB),
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  side: BorderSide(
                                    color: const Color(0xFF005BBB)
                                        .withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),

                            // ✅ LOCATION DETECTED BOX
                            if (_lat != null && _lng != null) ...[
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on,
                                        size: 20, color: Color(0xFF005BBB)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Location Detected\nLat: $_lat\nLng: $_lng",
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    // ✅ RE-FETCH BUTTON
                                    IconButton(
                                      onPressed: _getLocation,
                                      icon: const Icon(Icons.refresh,
                                          color: Color(0xFF005BBB)),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Radius
                            TextFormField(
                              controller: _radiusCtrl,
                              keyboardType: TextInputType.number,
                              decoration:
                                  inputDecor("Radius (meters)", Icons.radar),
                              validator: (v) {
                                if (v!.isEmpty) return "Radius required";
                                if (int.tryParse(v) == null) return "Invalid";
                                return null;
                              },
                            ),

                            const SizedBox(height: 32),

                            // ✅ SUBMIT BUTTON
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF002D62),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Add Location",
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
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
    );
  }

  InputDecoration inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF002D62), size: 20),
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
}
