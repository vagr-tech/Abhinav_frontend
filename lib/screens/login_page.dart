// ignore_for_file: prefer_const_constructors, deprecated_member_use, avoid_print

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'register_page.dart';
import '../services/call_log_service.dart';
import '../services/api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool loading = false;
  bool showPass = false;

  // static const Color darkBlue = Color(0xFF002D62);

  late AnimationController _anim;
  late Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    fadeAnim = CurvedAnimation(parent: _anim, curve: Curves.easeIn);
    _anim.forward();
  }

  Future<void> requestPermissions() async {
    var phone = await Permission.phone.request();

    if (phone.isGranted) {
      print("Phone permission granted");
    } else {
      print("Phone permission denied");
    }
  }

  Future<void> loginUser() async {
    if (mobileCtrl.text.isEmpty || passCtrl.text.isEmpty) {
      _msg("Mobile & Password are required");
      return;
    }

    setState(() => loading = true);

    final result = await AuthService.login(
      mobileCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    setState(() => loading = false);

    if (result["success"] != true) {
      _msg(result["message"] ?? "Login failed");
      return;
    }
    // 🔥 CALL LOG PERMISSION HERE
    await requestPermissions();

    // 🔹 shops fetch
    final shops = await ApiService.getShops();

    // 🔹 start call log tracking
    CallLogService.start(shops);

    // 🔥 IMPORTANT FIX (TOKEN SYNC)
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomePage(
          user: AuthService.currentUser ?? result["user"],
        ),
      ),
    );
  }

  void _msg(String txt, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          txt,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // 🔵 TOP CURVED HEADER
            Container(
              height: MediaQuery.of(context).size.height / 2.6,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF002D62),
                    Color(0xFF005BBB),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_on, size: 90, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    "Abhinav Tracking",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 50,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                  );
                },
                child: Column(
                  children: const [
                    Icon(Icons.app_registration, color: Colors.white, size: 28),
                    SizedBox(height: 4),
                    Text(
                      "Register",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  ],
                ),
              ),
            ),
            // ⚪ FLOATING CARD
            Container(
              margin: EdgeInsets.only(
                top: MediaQuery.of(context).size.height / 3.2,
                left: 20,
                right: 20,
              ),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  height: MediaQuery.of(context).size.height / 1.6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      const Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text("Mobile Number",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffececf8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: mobileCtrl,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Mobile Number",
                            prefixIcon: Icon(Icons.phone_android),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("Password",
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xffececf8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: passCtrl,
                          obscureText: !showPass,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Enter Password",
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                showPass
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () =>
                                  setState(() => showPass = !showPass),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                      Center(
                        child: loading
                            ? const CircularProgressIndicator()
                            : GestureDetector(
                                onTap: loginUser,
                                child: Container(
                                  width: 200,
                                  height: 55,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF002D62),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      "LOGIN",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
    );
  }
}
