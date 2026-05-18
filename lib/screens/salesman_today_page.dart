import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/shop_model.dart';
import 'shop_visit_page.dart';

class SalesmanTodayPage extends StatefulWidget {
  const SalesmanTodayPage({super.key});

  @override
  State<SalesmanTodayPage> createState() => _SalesmanTodayPageState();
}

class _SalesmanTodayPageState extends State<SalesmanTodayPage>
    with SingleTickerProviderStateMixin {
  bool loading = true;
  List today = [];
  List completed = [];

  late TabController tabCtrl;

  @override
  void initState() {
    super.initState();
    tabCtrl = TabController(length: 2, vsync: this);
    load(); // STEP 3 ✅
  }

  // --------------------------------------------------
  // LOAD TODAY & COMPLETED SHOPS
  // --------------------------------------------------
  Future<void> load() async {
    setState(() => loading = true);

    final data = await ApiService.getSalesmanToday();

    if (!mounted) return;

    setState(() {
      today = data["today"] ?? [];
      completed = data["completed"] ?? [];
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shops"),
        bottom: TabBar(
          controller: tabCtrl,
          tabs: const [
            Tab(text: "Today"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: tabCtrl,
              children: [
                buildList(today, false),
                buildList(completed, true),
              ],
            ),
    );
  }

  // --------------------------------------------------
  // SHOP LIST UI
  // --------------------------------------------------
  Widget buildList(List list, bool completedTab) {
    if (list.isEmpty) {
      return const Center(child: Text("No shops"));
    }

    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (_, i) {
        final shop = list[i];

        return Card(
          margin: const EdgeInsets.all(10),
          child: ListTile(
            leading: CircleAvatar(
              child: Text("${shop["sequence"]}"),
            ),
            title: Text(shop["shop_name"]),
            subtitle: Text(shop["segment"]),
            trailing: completedTab
                ? const Icon(Icons.check_circle, color: Colors.green)
                : ElevatedButton(
                    child: const Text("Visit"),
                    onPressed: () async {
                      // STEP 2 ✅ await + result handling
                      final visited = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopVisitPage(
                            shop: ShopModel(
  id: shop["_id"] ?? "",
  shopId: shop["shop_id"] ?? "",
  shopName: shop["shop_name"] ?? "",
  address: shop["address"] ?? "",
  lat: double.tryParse(shop["lat"].toString()) ?? 0,
  lng: double.tryParse(shop["lng"].toString()) ?? 0,
  segment: shop["segment"] ?? "",
)

                          ),
                        ),
                      );

                      // 🔥 AUTO REFRESH AFTER VISIT
                      if (visited == true) {
                        load();
                      }
                    },
                  ),
          ),
        );
      },
    );
  }
}
