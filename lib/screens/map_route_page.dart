// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class MapRoutePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const MapRoutePage({
    super.key,
    required this.user,
  });

  @override
  State<MapRoutePage> createState() => _MapRoutePageState();
}

class _MapRoutePageState extends State<MapRoutePage> {
  late MapController _mapController;

  // ── State ──
  bool loading = true;
  String selectedDateFilter = "Today";
  String? selectedSalesman;
  final dateOptions = ["Today", "Yesterday", "Last 7 Days"];

  // ── Data ──
  List<dynamic> allLogs = []; // ALL visits from API (no filter)
  List<String> salesmanList = []; // unique salesman names
  List<dynamic> filteredLogs = []; // after date+salesman filter
  List<LatLng> routePoints = [];
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAndBuild();
  }

  // ──────────────────────────────────────────────
  // Step 1: Fetch logs + salesman list in parallel
  // Salesman list comes from UserService (reliable)
  // Logs come from ApiService (for route drawing)
  // ──────────────────────────────────────────────
  Future<void> _fetchAndBuild() async {
    setState(() => loading = true);

    final role = widget.user["role"].toString().toLowerCase();
    final userName = widget.user["name"].toString();
    final userSegment = widget.user["segment"].toString().toUpperCase();

    // ── Fetch BOTH in parallel ──
    final results = await Future.wait([
      ApiService.getLogs(),
      UserService().getUsers(),
    ]);

    final rawResponse = results[0] as Map<String, dynamic>;
    final List<UserModel> allUsersList = results[1] as List<UserModel>;
    final List<dynamic> rawVisits = rawResponse["visits"] ?? [];

    debugPrint("🗺 MAP: total raw visits  => \${rawVisits.length}");
    debugPrint("🗺 MAP: total users fetched => ${allUsersList.length}");

    // ── Map visits to app format ──
    List<dynamic> mapped = rawVisits.map((l) {
      DateTime dt;
      try {
        dt = DateTime.parse(l["createdAt"]).toLocal();
      } catch (_) {
        dt = DateTime.now();
      }
      final bool isCall = (l["durationSec"] ?? 0) > 0;

      return {
        "pk": l["pk"],
        "sk": l["sk"],
        "shopName": l["shop_name"] ?? "",
        "salesman": l["salesmanName"] ?? "",
        "photoUrl": l["photo_url"] ?? "",
        "result": isCall ? null : l["result"] == "match",
        "isCall": isCall,
        "distance": double.tryParse(l["distance"].toString()) ?? 0.0,
        "date": DateFormat("dd-MM-yyyy").format(dt),
        "time": DateFormat("hh:mm a").format(dt).toUpperCase(),
        "segment": (l["segment"] ?? "").toString().toUpperCase(),
        "lat": _parseCoord(l["shopLat"] ?? l["latitude"] ?? l["shop_lat"]),
        "lng": _parseCoord(l["shopLng"] ?? l["longitude"] ?? l["shop_lng"]),
      };
    }).toList();

    // Role-based log filter
    if (role == "salesman") {
      mapped = mapped
          .where((l) => l["salesman"]
              .toString()
              .toLowerCase()
              .contains(userName.toLowerCase()))
          .toList();
    } else if (role == "manager") {
      mapped = mapped
          .where((l) => l["segment"].toString().toUpperCase() == userSegment)
          .toList();
    }

    allLogs = mapped;

    // ── Build salesman dropdown from UserService data ──
    _buildSalesmanList(allUsersList);
  }

  double? _parseCoord(dynamic val) {
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  // ──────────────────────────────────────────────
  // Step 2: Build salesman list from UserService
  // ✅ Independent of logs / coordinates
  // ──────────────────────────────────────────────
  void _buildSalesmanList(List<UserModel> allUsersList) {
    final role = widget.user["role"].toString().toLowerCase();
    final userSegment = widget.user["segment"].toString().toUpperCase();

    if (role == "salesman") {
      // Salesman: locked to own name — no dropdown
      selectedSalesman = widget.user["name"].toString();
      salesmanList = [];
    } else if (role == "manager") {
      // Manager: only salesmen in their segment
      final names = allUsersList
          .where((u) =>
              u.role.toLowerCase() == "salesman" &&
              u.segment.toUpperCase() == userSegment)
          .map((u) => u.name.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      salesmanList = names;
      selectedSalesman = names.isNotEmpty ? names.first : null;
    } else {
      // Master: all salesmen from all segments
      final names = allUsersList
          .where((u) => u.role.toLowerCase() == "salesman")
          .map((u) => u.name.trim())
          .where((n) => n.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      salesmanList = names;
      selectedSalesman = names.isNotEmpty ? names.first : null;
    }

    debugPrint("🗺 MAP salesmanList => $salesmanList");
    debugPrint("🗺 MAP selectedSalesman => $selectedSalesman");

    // Step 3: apply date + salesman filter
    _applyFilters();
  }

  // ──────────────────────────────────────────────
  // Step 3: Filter by date + salesman for map
  // Coordinates checked ONLY here
  // ──────────────────────────────────────────────
  void _applyFilters() {
    if (selectedSalesman == null) {
      setState(() {
        filteredLogs = [];
        routePoints = [];
        loading = false;
      });
      return;
    }

    final validDates = _getDateStrings();

    final result = allLogs.where((l) {
      final isMatch = l["result"] == true && l["isCall"] == false;
      final hasCoords = l["lat"] != null && l["lng"] != null;
      final dateMatch = validDates.contains(l["date"].toString());
      final nameMatch = (l["salesman"] ?? "").toString().toLowerCase().trim() ==
          selectedSalesman!.toLowerCase().trim();
      return isMatch && hasCoords && dateMatch && nameMatch;
    }).toList();

    // Sort by date+time ascending
    result.sort((a, b) {
      try {
        final da =
            DateFormat("dd-MM-yyyy hh:mm a").parse("${a["date"]} ${a["time"]}");
        final db =
            DateFormat("dd-MM-yyyy hh:mm a").parse("${b["date"]} ${b["time"]}");
        return da.compareTo(db);
      } catch (_) {
        return 0;
      }
    });

    final points = result
        .map((l) => LatLng(
              (l["lat"] as num).toDouble(),
              (l["lng"] as num).toDouble(),
            ))
        .toList();

    setState(() {
      filteredLogs = result;
      routePoints = points;
      selectedIndex = null;
      loading = false;
    });

    debugPrint(
        "🗺 MAP: filteredLogs for $selectedSalesman => ${result.length}");

    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  List<String> _getDateStrings() {
    final fmt = DateFormat("dd-MM-yyyy");
    final now = DateTime.now();
    if (selectedDateFilter == "Today") {
      return [fmt.format(now)];
    } else if (selectedDateFilter == "Yesterday") {
      return [fmt.format(now.subtract(const Duration(days: 1)))];
    } else {
      return List.generate(
          7, (i) => fmt.format(now.subtract(Duration(days: i))));
    }
  }

  // ──────────────────────────────────────────────
  void _fitBounds() {
    if (routePoints.isEmpty) return;
    if (routePoints.length == 1) {
      _mapController.move(routePoints.first, 15);
      return;
    }
    final lats = routePoints.map((p) => p.latitude);
    final lngs = routePoints.map((p) => p.longitude);
    _mapController.fitCamera(CameraFit.bounds(
      bounds: LatLngBounds(
        LatLng(lats.reduce((a, b) => a < b ? a : b) - 0.005,
            lngs.reduce((a, b) => a < b ? a : b) - 0.005),
        LatLng(lats.reduce((a, b) => a > b ? a : b) + 0.005,
            lngs.reduce((a, b) => a > b ? a : b) + 0.005),
      ),
      padding: const EdgeInsets.all(52),
    ));
  }

  // ──────────────────────────────────────────────
  // Markers
  // ──────────────────────────────────────────────
  List<Marker> _buildMarkers() {
    return List.generate(filteredLogs.length, (i) {
      final isSelected = selectedIndex == i;
      final isFirst = i == 0 && filteredLogs.length > 1;
      final isLast = i == filteredLogs.length - 1 && filteredLogs.length > 1;
      final color = isFirst
          ? Colors.green.shade700
          : isLast
              ? Colors.red.shade600
              : const Color(0xFF005BBB);

      return Marker(
        point: routePoints[i],
        width: isSelected ? 54 : 42,
        height: isSelected ? 54 : 42,
        child: GestureDetector(
          onTap: () =>
              setState(() => selectedIndex = selectedIndex == i ? null : i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF002D62) : color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.22),
                    blurRadius: 6,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Center(
              child: Text("${i + 1}",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isSelected ? 15 : 12)),
            ),
          ),
        ),
      );
    });
  }

  // ──────────────────────────────────────────────
  // Filter bar
  // ──────────────────────────────────────────────
  Widget _buildFilterBar() {
    final isSalesman =
        widget.user["role"].toString().toLowerCase() == "salesman";

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date chips
          Row(
            children: dateOptions.map((opt) {
              final active = selectedDateFilter == opt;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => selectedDateFilter = opt);
                    _applyFilters();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: active
                          ? const Color(0xFF002D62)
                          : const Color(0xFFE3ECF7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(opt,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white
                                : const Color(0xFF002D62))),
                  ),
                ),
              );
            }).toList(),
          ),

          // Salesman dropdown — master & manager only
          if (!isSalesman && salesmanList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButton<String>(
                value: selectedSalesman,
                isExpanded: true,
                underline: const SizedBox(),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Color(0xFF002D62)),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF002D62)),
                items: salesmanList
                    .map((name) => DropdownMenuItem(
                          value: name,
                          child: Row(children: [
                            const Icon(Icons.person_outline,
                                size: 16, color: Color(0xFF005BBB)),
                            const SizedBox(width: 8),
                            Text(name),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() => selectedSalesman = v);
                  _applyFilters();
                },
              ),
            ),
          ],

          // Salesman role: show locked name as chip
          if (isSalesman) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3ECF7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.lock_outline,
                    size: 15, color: Color(0xFF002D62)),
                const SizedBox(width: 8),
                Text(
                  selectedSalesman ?? "",
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF002D62)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Summary strip
  // ──────────────────────────────────────────────
  Widget _buildSummaryStrip() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF002D62).withOpacity(0.90),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        const Icon(Icons.route, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "${filteredLogs.length} matched visit${filteredLogs.length != 1 ? 's' : ''}  •  $selectedDateFilter",
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (routePoints.isNotEmpty)
          GestureDetector(
            onTap: _fitBounds,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(children: [
                Icon(Icons.zoom_out_map, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text("Fit",
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
      ]),
    );
  }

  // ──────────────────────────────────────────────
  // Bottom info card
  // ──────────────────────────────────────────────
  Widget _buildInfoCard() {
    if (selectedIndex == null) return const SizedBox.shrink();
    final log = filteredLogs[selectedIndex!];
    return Positioned(
      left: 14,
      right: 14,
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 14,
                offset: const Offset(0, 5))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
                color: Color(0xFF002D62), shape: BoxShape.circle),
            child: Center(
              child: Text("${selectedIndex! + 1}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log["shopName"] ?? "",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Text("${log["date"]}  ${log["time"]}",
                    style:
                        const TextStyle(fontSize: 12, color: Colors.black54)),
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 13, color: Colors.black38),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(log["salesman"] ?? "",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54),
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.social_distance,
                      size: 13, color: Color(0xFF005BBB)),
                  const SizedBox(width: 4),
                  Text("${(log["distance"] as num).toStringAsFixed(1)} m",
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF005BBB),
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),
          if ((log["photoUrl"] ?? "") != "") ...[
            const SizedBox(width: 8),
            CircleAvatar(
                radius: 22, backgroundImage: NetworkImage(log["photoUrl"])),
          ],
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => selectedIndex = null),
            child: const Icon(Icons.close, color: Colors.black38, size: 20),
          ),
        ]),
      ),
    );
  }

  Widget _legendDot(Color color, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54)),
          const SizedBox(width: 6),
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5))),
        ],
      );

  // ──────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              // MAP
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: routePoints.isNotEmpty
                      ? routePoints.first
                      : const LatLng(11.1271, 78.6569),
                  initialZoom: 13,
                  onTap: (_, __) => setState(() => selectedIndex = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.yourapp.salestracker",
                  ),
                  if (routePoints.length > 1)
                    PolylineLayer(polylines: [
                      Polyline(
                          points: routePoints,
                          strokeWidth: 3.5,
                          color: const Color(0xFF005BBB)),
                    ]),
                  MarkerLayer(markers: _buildMarkers()),
                ],
              ),

              // TOP OVERLAYS
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8)
                              ],
                            ),
                            child: const Icon(Icons.arrow_back,
                                color: Color(0xFF002D62), size: 20),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8)
                              ],
                            ),
                            child: Text(
                              selectedSalesman != null
                                  ? "🗺  ${selectedSalesman!}'s Route"
                                  : "🗺  Route Map",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF002D62)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ]),
                    ),
                    _buildFilterBar(),
                    _buildSummaryStrip(),
                  ],
                ),
              ),

              // Legend
              if (selectedIndex == null && filteredLogs.length > 1)
                Positioned(
                  right: 14,
                  bottom: 24,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _legendDot(Colors.green.shade700, "Start"),
                      const SizedBox(height: 6),
                      _legendDot(Colors.red.shade600, "End"),
                      const SizedBox(height: 6),
                      _legendDot(const Color(0xFF005BBB), "Visit"),
                    ],
                  ),
                ),

              // Info card
              _buildInfoCard(),

              // Empty state
              if (filteredLogs.isEmpty)
                Center(
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.93),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_off,
                              size: 46, color: Colors.black26),
                          const SizedBox(height: 12),
                          Text(
                            selectedSalesman != null
                                ? "No matched visits\nfor $selectedSalesman\non $selectedDateFilter"
                                : "No data found",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.black45, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ]),
    );
  }
}
