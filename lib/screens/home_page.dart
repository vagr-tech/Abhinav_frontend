// ignore_for_file: deprecated_member_use, unused_local_variable, prefer_const_constructors

import 'package:abhinav_tracking/screens/report_page.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import 'shop_list_page.dart';
import 'pending_shops_page.dart';
import 'user_list_page.dart';

import 'log_history_filter_page.dart';
import 'add_shop_page.dart';

const String appLogo =
    "https://res.cloudinary.com/de46qan00/image/upload/v1765565348/logo_bbvbky.png";

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  static const Color darkBlue = Color(0xFF002D62);
  int selectedIndex = 0; // ✅ HERE
  late AnimationController _controller;
  late Animation<double> fadeAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> logout() async {
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    final String name = user["name"]?.toString() ?? "User";
    final String mobile = user["mobile"]?.toString() ?? "-";
    final String role = user["role"]?.toString().toLowerCase() ?? "";
    final String segment = user["segment"]?.toString() ?? "-";

    final bool isMaster = role == "master";
    final bool isManager = role == "manager";
    final bool isSalesman = role == "salesman";

    List<Widget> pages = [];
    List<BottomNavigationBarItem> navItems = [];

// ✅ Dashboard for Master & Manager
    if (isMaster || isManager) {
      pages.add(DashboardPage(user: widget.user));
      navItems.add(const BottomNavigationBarItem(
        icon: Tooltip(message: "Dashboard", child: Icon(Icons.dashboard)),
        label: "Dashboard",
      ));
    }

// History
    pages.add(LogHistoryFilterPage(user: widget.user));
    navItems.add(const BottomNavigationBarItem(
      icon: Tooltip(message: "History Log", child: Icon(Icons.history)),
      label: "History",
    ));

// Shops
    pages.add(ShopListPage(user: widget.user));
    navItems.add(const BottomNavigationBarItem(
      icon: Tooltip(message: "Shop List", child: Icon(Icons.store)),
      label: "Shops",
    ));
    if (isMaster || isManager) {
      pages.add(PendingShopsPage(
        user: widget.user,
        isFromTab: true,
      ));
      navItems.add(const BottomNavigationBarItem(
        icon: Tooltip(
            message: "Pending Shops", child: Icon(Icons.pending_actions)),
        label: "Pending",
      ));
    }

    if (isMaster) {
      pages.add(const UserListPage());
      navItems.add(const BottomNavigationBarItem(
        icon: Tooltip(message: "User List", child: Icon(Icons.people)),
        label: "User",
      ));
    }

    if (isSalesman) {
      pages.add(const AddShopPage());
      navItems.add(const BottomNavigationBarItem(
        icon: Tooltip(message: "Add Shop", child: Icon(Icons.add_business)),
        label: "Add",
      ));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          // 🔵 Compact Gradient Header (AppBar Style)
          // 🔵 Compact Gradient Header
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 18,
              right: 12,
              bottom: 16,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFEAF0F8),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF002D62),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF002D62),
                          ),
                        ),
                        TextSpan(
                          text: " • ${role.toUpperCase()}",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: logout,
                  icon: const Icon(
                    Icons.logout,
                    color: Color(0xFF002D62),
                  ),
                ),
              ],
            ),
          ),

          // ✅ FULL PAGE AREA (Not stacked look)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                child: pages[selectedIndex],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: darkBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true, // ✅ enable
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
        ),

        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
        ),
        items: navItems,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
