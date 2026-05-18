// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../screens/log_history_filter_page.dart';
import '../screens/shop_list_page.dart';
import '../screens/sales_orders_page.dart'; // ← top add 
import '../screens/shops_outstanding_page.dart';

class DashboardPage extends StatelessWidget {
  final Map<String, dynamic> user;
  const DashboardPage({super.key, required this.user});

  bool isMaster() => user["role"]?.toString().toLowerCase() == "master";
  bool isManager() => user["role"]?.toString().toLowerCase() == "manager";
  bool isSalesman() => user["role"]?.toString().toLowerCase() == "salesman";

  static const Color darkBlue = Color(0xFF002D62); // DARK BLUE

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      // ⭐ LOGOUT BUTTON ADDED
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(context, "/login", (_) => false);
            },
            icon: const Icon(Icons.logout, color: darkBlue, size: 28),
          )
        ],
      ),

      extendBodyBehindAppBar: true,

      body: Container(

        // 💙 SAME FULL BLUE GRADIENT
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF007FFF),
              Color(0xFF2A52BE),
              Color(0xFF6BA7FF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 80),

            // 💙 USER CARD (NOW WHITE + DARK BLUE TEXT)
            _buildUserCard(),

            const SizedBox(height: 25),

            // 💙 WHITE TILES + DARK BLUE ICONS
            _tile(
              icon: Icons.history,
              title: "History Log",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LogHistoryFilterPage(user: user),
                  ),
                );
              },
            ),
const SizedBox(height: 15),

if (isMaster() || isManager())
  _tile(
    icon: Icons.account_balance_wallet,
    title: "Shop Outstanding",
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ShopsOutstandingPage(),
        ),
      );
    },
  ),            // existing tiles கீழே இதை add பண்ணுங்க:
const SizedBox(height: 15),

if (isMaster() || isManager())
  _tile(
    icon: Icons.receipt_long,
    title: "Sales Orders",
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SalesOrdersPage(),
        ),
      );
    },
  ),
            const SizedBox(height: 15),

            _tile(
              icon: Icons.storefront,
              title: "Shop List",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopListPage(user: user),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            if (isMaster() || isManager())
              _tile(
                icon: Icons.people_alt,
                title: "User List",
                onTap: () {},
              ),

            const SizedBox(height: 15),

            _tile(
              icon: Icons.location_on,
              title: "Location Match",
              onTap: () {},
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ⭐ WHITE TILE + DARK BLUE ICON + DARK BLUE TEXT
  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: darkBlue),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: darkBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐ WHITE USER CARD + DARK BLUE FONT
  Widget _buildUserCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.blueAccent.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Welcome",
            style: TextStyle(color: darkBlue, fontSize: 14),
          ),

          const SizedBox(height: 5),

          Text(
            user["name"] ?? "User",
            style: const TextStyle(
              color: darkBlue,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            "Mobile: ${user["mobile"] ?? "-"}",
            style: const TextStyle(color: darkBlue),
          ),

          const SizedBox(height: 4),

          Text(
            "Role: ${user["role"] ?? "-"}",
            style: const TextStyle(color: darkBlue),
          ),

          const SizedBox(height: 4),

          Text(
            "Segment: ${user["segment"] ?? "-"}",
            style: const TextStyle(color: darkBlue),
          ),
        ],
      ),
    );
  }
}
