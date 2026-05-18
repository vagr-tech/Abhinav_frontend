// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart' as auth;
import 'add_user_page.dart';
import 'edit_user_page.dart';
import '../utils/date_utils.dart';

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  final UserService userService = UserService();

  List<UserModel> allUsers = [];
  List<UserModel> filteredUsers = [];

  final TextEditingController searchCtrl = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();

    searchCtrl.addListener(() {
      searchFilter(searchCtrl.text.trim());
    });
  }

  // ------------------------------------------------------
  // LOAD USERS
  // ------------------------------------------------------
  Future<void> loadUsers() async {
    setState(() => loading = true);

    final users = await userService.getUsers(); // corrected API call

    allUsers = users;
    allUsers
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    filteredUsers = allUsers;

    if (mounted) {
      setState(() => loading = false);
    }
  }

  // ------------------------------------------------------
  // SEARCH
  // ------------------------------------------------------
  void searchFilter(String text) {
    final q = text.toLowerCase();

    setState(() {
      if (q.isEmpty) {
        filteredUsers = allUsers;
      } else {
        filteredUsers = allUsers.where((u) {
          return u.name.toLowerCase().contains(q) ||
              u.mobile.toLowerCase().contains(q) ||
              u.role.toLowerCase().contains(q) ||
              u.segment.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  // ------------------------------------------------------
  // DELETE USER
  // ------------------------------------------------------
  Future<void> deleteUser(UserModel u) async {
    final confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text("Delete user '${u.name}'?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await userService.deleteUser(u.userId);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User deleted")));
      loadUsers();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Delete failed")));
    }
  }

  @override
  Widget build(BuildContext context) {
    // MASTER ONLY ACCESS (UNCHANGED)
    if (auth.AuthService.currentUser?["role"]?.toLowerCase() != "master") {
      return const Scaffold(
        body: Center(
          child: Text(
            "Access Denied",
            style: TextStyle(fontSize: 22, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: Stack(
        children: [
          // ✅ CURVED HEADER BACKGROUND (Same as Filter Page)
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

          // ✅ MAIN FLOATING CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ✅ PAGE TITLE (Same Style)
                  const Text(
                    "Users List",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // ✅ FLOATING WHITE CARD (Exact Like Filter Page)
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
                          // 🔍 SEARCH BAR (UNCHANGED LOGIC)
                          TextField(
                            controller: searchCtrl,
                            decoration: InputDecoration(
                              hintText:
                                  "Search by name, mobile, role, segment...",
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: searchCtrl.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        searchCtrl.clear();
                                        searchFilter("");
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: const Color(0xFFF4F7FC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ✅ USER LIST (SCROLLABLE INSIDE CARD)
                          Expanded(
                            child: loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : filteredUsers.isEmpty
                                    ? const Center(
                                        child: Text(
                                          "No users found",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54),
                                        ),
                                      )
                                    : ListView.builder(
                                        itemCount: filteredUsers.length,
                                        itemBuilder: (_, i) {
                                          return _userCard(filteredUsers[i]);
                                        },
                                      ),
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

      // FAB (UNCHANGED)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddUserPage()),
          ).then((_) => loadUsers());
        },
      ),
    );
  }

  // ------------------------------------------------------
  // USER CARD
  // ------------------------------------------------------
  Widget _userCard(UserModel u) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 TOP ROW (Avatar + Name + Role Badge + Actions)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF1565C0),
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : "?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Name + Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      u.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Role Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3ECF7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        u.role.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Edit & Delete Icons (Professional look)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        size: 20, color: Color(0xFF0D47A1)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditUserPage(user: u)),
                      ).then((_) => loadUsers());
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: Colors.red),
                    onPressed: () => deleteUser(u),
                  ),
                ],
              )
            ],
          ),

          const SizedBox(height: 14),

          // 🔹 Divider
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.15),
          ),

          const SizedBox(height: 12),

          // 🔹 DETAILS SECTION
          _detailRow(Icons.phone, "Mobile", u.mobile),
          const SizedBox(height: 6),
          _detailRow(Icons.category, "Segment", u.segment),
          const SizedBox(height: 6),
          _detailRow(
              Icons.access_time, "Created", formatIST(u.createdAt ?? "")),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF0D47A1)),
        const SizedBox(width: 8),
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
