// ignore_for_file: deprecated_member_use, prefer_interpolation_to_compose_strings

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AddUserPage extends StatefulWidget {
  const AddUserPage({super.key});

  @override
  State<AddUserPage> createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final mobileCtrl = TextEditingController();

  String role = "salesman";
  String segment = "fmcg";

  final userService = UserService();
  bool loading = false;

  final Color darkBlue = const Color(0xFF002D62);

  Future<void> createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    final autoPassword = mobileCtrl.text.substring(6) + "@$role";

    final user = UserModel(
      userId: "",
      name: nameCtrl.text.trim(),
      mobile: mobileCtrl.text.trim(),
      role: role,
      segment: segment,
      password: autoPassword,
    );

    final ok = await userService.addUser(user);

    if (!mounted) return;
    setState(() => loading = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User Created\nPassword: $autoPassword")),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Create failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 🔵 Gradient Header
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [darkBlue, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    "Add User",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔥 Floating Card Section
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _field(nameCtrl, "Name"),
                          _field(mobileCtrl, "Mobile",
                              keyboard: TextInputType.phone),
                          DropdownButtonFormField(
                            value: role,
                            decoration: _decor("Role"),
                            items: const [
                              DropdownMenuItem(
                                  value: "master", child: Text("Master")),
                              DropdownMenuItem(
                                  value: "manager", child: Text("Manager")),
                              DropdownMenuItem(
                                  value: "salesman", child: Text("Salesman")),
                            ],
                            onChanged: (v) =>
                                setState(() => role = v.toString()),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField(
                            value: segment,
                            decoration: _decor("Segment"),
                            items: const [
                              DropdownMenuItem(
                                  value: "fmcg", child: Text("FMCG")),
                              DropdownMenuItem(
                                  value: "pipes", child: Text("PIPES")),
                            ],
                            onChanged: (v) =>
                                setState(() => segment = v.toString()),
                          ),
                          const SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: darkBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: loading ? null : createUser,
                              child: loading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      "Create User",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        decoration: _decor(label),
        validator: (v) => v!.isEmpty ? "Enter $label" : null,
      ),
    );
  }

  InputDecoration _decor(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
