// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unnecessary_null_comparison

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async'; // for Timer
import '../services/shop_service.dart';
import '../services/auth_service.dart';
import '../helpers/location_helper.dart';

import '../helpers/web_camera_stub.dart'
    if (dart.library.html) '../helpers/web_camera_helper.dart';

import '../helpers/web_location_helper_stub.dart'
    if (dart.library.html) '../helpers/web_location_helper.dart';

import 'package:http/http.dart' as http;

class AddShopPage extends StatefulWidget {
  const AddShopPage({super.key});

  @override
  State<AddShopPage> createState() => _AddShopPageState();
}

class _AddShopPageState extends State<AddShopPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController primaryPhoneController = TextEditingController();
  final TextEditingController secondaryPhoneController =
      TextEditingController();
  String gstType = "non_gst"; // default
  final TextEditingController gstController = TextEditingController();
  String? selectedShopType;
  String? selectedSegment;
  File? imageFile;
  String? base64Image;

  double? lat;
  double? lng;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    gstController.addListener(_onGstChanged);
  }

// Debounce timer to avoid calling API on every keystroke
  Timer? _gstDebounce;

  void _onGstChanged() {
    final gst = gstController.text.trim();
    print("GST CHANGED: $gst | length: ${gst.length}"); // ← add this

    if (gst.length != 15) return;

    _gstDebounce?.cancel();
    _gstDebounce = Timer(const Duration(milliseconds: 600), () async {
      print("GST DEBOUNCE FIRED: $gst"); // ← add this
      await _autoFillFromGst(gst);
    });
  }

  Future<void> _autoFillFromGst(String gst) async {
    try {
      final data = await ShopService.fetchShopByGst(gst);

      if (!mounted) return;

      if (data == null) {
        // No match — silently do nothing, let user fill manually
        return;
      }

      setState(() {
        nameController.text = data["shop_name"] ?? "";
        addressController.text = data["address"] ?? "";
        primaryPhoneController.text = data["primaryPhone"] ?? "";
        secondaryPhoneController.text = data["secondaryPhone"] ?? "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Shop details auto-filled from GST"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      // Non-blocking: show subtle error, don't block the form
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("GST lookup failed: $e"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================
  // PICK PHOTO POPUP
  // ==========================================
  Future pickPhoto() async {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () async {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Choose File / Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // CAMERA PICK (WEB + MOBILE)
  // ==========================================
  Future _pickFromCamera() async {
    if (kIsWeb) {
      bool hasCam = await WebCameraHelper.hasWebCamera();

      if (!hasCam) {
        _error("No Camera Detected");
        return;
      }

      WebCameraHelper.pickFromCamera((base64) async {
        if (base64 == null || base64.isEmpty) {
          _error("Camera capture failed");
          return;
        }

        if (!mounted) return;

        setState(() => base64Image = base64);

        await Future.delayed(const Duration(milliseconds: 300));

        getLocation();
      });

      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 25,
      maxWidth: 800,
    );

    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        imageFile = file;
        base64Image = base64Encode(bytes);
      });

      await Future.delayed(const Duration(milliseconds: 200));

      getLocation();
    }
  }

  // ==========================================
  // GALLERY PICK (WEB + MOBILE)
  // ==========================================
  Future _pickFromGallery() async {
    if (kIsWeb) {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.image, withData: true);
      if (result != null) {
        base64Image = base64Encode(result.files.single.bytes!);
        imageFile = null;
        setState(() {});
        getLocation();
      }
      return;
    }

    if (Platform.isWindows) {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        imageFile = File(result.files.single.path!);
        base64Image = base64Encode(await imageFile!.readAsBytes());
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 200));
        getLocation();
      }
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 25,
      maxWidth: 800,
    );
    if (picked != null) {
      imageFile = File(picked.path);
      base64Image = base64Encode(await imageFile!.readAsBytes());
      setState(() {});
      getLocation();
    }
  }

  // ==========================================
  // GET LOCATION
  // ==========================================
  Future getLocation() async {
    if (kIsWeb) {
      final blocked = await WebLocationHelper.isLocationBlocked();
      if (blocked) {
        WebLocationHelper.showLocationBlockedDialog(context);
        return;
      }
    }

    final pos = await LocationHelper.getLocation();
    if (!mounted) return;
    if (pos == null) {
      _error("Enable location permission");
      return;
    }

    lat = pos.latitude;
    lng = pos.longitude;

    setState(() {});
  }

  // ==========================================
  // SUBMIT SHOP → SEND TO PENDING SHOPS
  // ==========================================
  Future submit() async {
    // ================= DEBUG POPUP =================
    void debugBox(String msg) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("DEBUG"),
          content: SingleChildScrollView(child: Text(msg)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }

    // ================= BASIC VALIDATION =================
    if (nameController.text.isEmpty) return _error("Enter shop name");
    if (addressController.text.isEmpty) return _error("Enter address");
    if (selectedSegment == null) return _error("Select segment");
    if (base64Image == null) return _error("Select a photo");
    if (lat == null || lng == null) return _error("Location not detected");
    if (primaryPhoneController.text.isEmpty) {
      return _error("Enter primary phone");
    }
    if (selectedShopType == null) {
      return _error("Select shop type");
    }

    // ================= TOKEN CHECK (🔥 MAIN FIX) =================
    if (AuthService.token == null) {
      debugBox("TOKEN NOT READY ❌\nWait 2 seconds and try again");
      return;
    }

    final payload = {
      "shop_name": nameController.text.trim(),
      "address": addressController.text.trim(),
      "lat": lat,
      "lng": lng,
      "segment": selectedSegment,
      "shopImage": base64Image,
      "primaryPhone": primaryPhoneController.text.trim(),
      "secondaryPhone": secondaryPhoneController.text.trim(),
      "shopType": selectedShopType,
      "gstType": gstType,
      "gstNumber": gstController.text,
    };

    setState(() => loading = true);

    final url = Uri.parse(
      "https://abhinav-backend-z8tm.onrender.com/api/shops/add",
    );

    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${AuthService.token}",
        },
        body: jsonEncode(payload),
      );

      setState(() => loading = false);

      // ================= STATUS CHECK =================
      if (res.statusCode != 200) {
        debugBox(
          "SERVER ERROR ❌\n"
          "Status: ${res.statusCode}\n"
          "Body:\n${res.body}",
        );
        return;
      }

      final data = jsonDecode(res.body);

      if (data["success"] == true) {
        _success("Shop submitted for approval");

        // ✅ Reset form instead of pop (avoid black screen)
        gstController.clear();
        nameController.clear();
        addressController.clear();
        primaryPhoneController.clear();
        secondaryPhoneController.clear();

        selectedSegment = null;
        selectedShopType = null;

        base64Image = null;
        imageFile = null;
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
        lat = null;
        lng = null;

        setState(() {});
      } else {
        _error(data["message"] ?? "Submit failed");
      }
    } catch (e) {
      setState(() => loading = false);
      debugBox("NETWORK / CRASH ERROR ❌\n$e");
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _success(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  @override
  void dispose() {
    _gstDebounce?.cancel();
    gstController.removeListener(_onGstChanged);
    nameController.dispose();
    addressController.dispose();
    primaryPhoneController.dispose();
    secondaryPhoneController.dispose();
    gstController.dispose();
    super.dispose();
  }

  // ==========================================
  // UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // ✅ CURVED HEADER SAME AS FILTER PAGE
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

                  // ✅ TITLE LIKE FILTER PAGE
                  const Text(
                    "Add Shop",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Enter shop details & submit for approval",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ✅ FLOATING FORM CARD SAME AS FILTER PAGE
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
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile(
                                  value: "gst",
                                  groupValue: gstType,
                                  title: const Text("GST"),
                                  onChanged: (value) {
                                    setState(() {
                                      gstType = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile(
                                  value: "non_gst",
                                  groupValue: gstType,
                                  title: const Text("Non GST"),
                                  onChanged: (value) {
                                    setState(() {
                                      gstType = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (gstType == "gst") ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: gstController,
                              decoration: inputDecor("Enter GST Number"),
                            ),
                          ],
                          // ✅ INPUTS
                          TextField(
                            controller: nameController,
                            decoration: inputDecor("Shop Name"),
                          ),
                          const SizedBox(height: 18),

                          TextField(
                            controller: addressController,
                            decoration: inputDecor("Address"),
                          ),
                          const SizedBox(height: 18),

                          TextField(
                            controller: primaryPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: inputDecor("Primary Phone"),
                          ),

                          const SizedBox(height: 18),

                          TextField(
                            controller: secondaryPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration:
                                inputDecor("Secondary Phone (Optional)"),
                          ),

                          const SizedBox(height: 18),

                          DropdownButtonFormField<String>(
                            value: selectedShopType,
                            decoration: inputDecor("Shop Type"),
                            items: const [
                              DropdownMenuItem(
                                value: "office",
                                child: Text("Office"),
                              ),
                              DropdownMenuItem(
                                value: "warehouse",
                                child: Text("Warehouse"),
                              ),
                              DropdownMenuItem(
                                value: "godown",
                                child: Text("Godown"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedShopType = value;
                              });
                            },
                          ),
// ✅ ACTION SECTION CARD (Makes buttons not feel alone)
                          const SizedBox(height: 18),

                          DropdownButtonFormField<String>(
                            value: selectedSegment,
                            decoration: inputDecor("Select Segment"),
                            items: const [
                              DropdownMenuItem(
                                value: "fmcg",
                                child: Text("FMCG"),
                              ),
                              DropdownMenuItem(
                                value: "pipes",
                                child: Text("Pipes"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSegment = value;
                              });
                            },
                          ),
                          const SizedBox(height: 25),
                          Column(
                            children: [
                              // 📷 TAKE PHOTO BUTTON (Outlined Premium)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: pickPhoto,
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Color(0xFF005BBB),
                                  ),
                                  label: const Text(
                                    "Take Shop Photo",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF005BBB),
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15),
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

                              if (base64Image != null) ...[
                                const SizedBox(height: 14),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.memory(
                                    base64Decode(base64Image!),
                                    cacheWidth: 400,
                                    gaplessPlayback: true,
                                    height: 170,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
// ✅ LOCATION DISPLAY BOX
                              if (lat != null && lng != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 18),
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
                                      const Icon(
                                        Icons.my_location,
                                        size: 20,
                                        color: Color(0xFF005BBB),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          "Location Detected\nLat: $lat\nLng: $lng",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 20),

                              // ✅ SUBMIT BUTTON (Main CTA Premium)
                              loading
                                  ? const Center(
                                      child: CircularProgressIndicator())
                                  : SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: submit,
                                        icon: const Icon(
                                          Icons.check_circle_outline,
                                          size: 20,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          "Submit for Approval",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          elevation: 3,
                                          shadowColor: Colors.black26,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
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
}

InputDecoration inputDecor(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Color(0xFF002D62)),
    filled: true,
    fillColor: const Color(0xFFF4F7FC),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 16,
    ),
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
      borderSide: const BorderSide(
        color: Color(0xFF005BBB),
        width: 1.5,
      ),
    ),
  );
}
