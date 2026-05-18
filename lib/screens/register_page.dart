// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController companyIdCtrl = TextEditingController();
  final TextEditingController companyNameCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();

  bool loading = false;
  bool showPass = false;

  Future<void> registerMaster() async {
    if (companyNameCtrl.text.isEmpty ||
        nameCtrl.text.isEmpty ||
        mobileCtrl.text.isEmpty ||
        passCtrl.text.isEmpty) {
      _msg("All fields are required");
      return;
    }

    setState(() => loading = true);

    final result = await AuthService.registerMaster(
      companyNameCtrl.text.trim(),
      nameCtrl.text.trim(),
      mobileCtrl.text.trim(),
      passCtrl.text.trim(),
    );

    setState(() => loading = false);

    if (result["success"] != true) {
      _msg(result["message"] ?? "Registration failed");
      return;
    }

    _msg("Master Registered Successfully", isError: false);
    Navigator.pop(context);
  }

  void _msg(String txt, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(txt, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
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
              child: Stack(
                children: [
                  // 🔙 Back Button
                  Positioned(
                    top: 40,
                    left: 15,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),

                  // 🔷 Center Content
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.app_registration,
                            size: 90, color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          "Register Master",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      _input("Company Name", companyNameCtrl, Icons.apartment),
                      _input("Your Name", nameCtrl, Icons.person),
                      _input("Mobile", mobileCtrl, Icons.phone),
                      _input("Password", passCtrl, Icons.lock,
                          isPassword: true),
                      const SizedBox(height: 30),
                      loading
                          ? const CircularProgressIndicator()
                          : GestureDetector(
                              onTap: registerMaster,
                              child: Container(
                                width: 200,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF002D62),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: const Center(
                                  child: Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 30),
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

  Widget _input(String hint, TextEditingController ctrl, IconData icon,
      {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xffececf8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: ctrl,
          obscureText: isPassword ? !showPass : false,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            prefixIcon: Icon(icon),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                        showPass ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => showPass = !showPass),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
