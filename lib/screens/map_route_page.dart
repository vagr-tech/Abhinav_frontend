// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

// ── Live location model ────────────────────────────────────
class _LiveLocation {
  final String salesmanName;
  final double lat;
  final double lng;
  final int updatedAt; // epoch seconds

  const _LiveLocation({
    required this.salesmanName,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory _LiveLocation.fromJson(Map<String, dynamic> j) => _LiveLocation(
        salesmanName: j['salesmanName'] ?? '',
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        updatedAt: (j['updatedAt'] as num).toInt(),
      );

  /// How many minutes ago was this updated
  int get minutesAgo =>
      ((DateTime.now().millisecondsSinceEpoch ~/ 1000) - updatedAt) ~/ 60;

  bool get isStale => minutesAgo > 5; // grey out if > 5 mins old
}

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

  // ── Matched-visit data (existing) ──
  List<dynamic> allLogs = [];
  List<String> salesmanList = [];
  List<dynamic> filteredLogs = [];
  List<LatLng> routePoints = [];
  int? selectedIndex;

  // ── Live location data (NEW) ──
  // Map: salesmanName → _LiveLocation
  Map<String, _LiveLocation> _liveLocations = {};
  Timer? _liveRefreshTimer;
  bool _showLive = true; // toggle live dots on/off

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fetchAndBuild();
    _startLiveRefresh(); // NEW: start live polling
  }

  @override
  void dispose() {
    _liveRefreshTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────
  // LIVE: Poll backend every 1 minute for current positions
  // ──────────────────────────────────────────────────────────
  void _startLiveRefresh() {
    _fetchLiveLocations(); // fetch immediately
    _liveRefreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _fetchLiveLocations(),
    );
  }

  Future<void> _fetchLiveLocations() async {
    try {
      final response = await ApiService.getLiveLocations();
      final List<dynamic> rawList = response['locations'] ?? [];
      final Map<String, _LiveLocation> updated = {};
      for (final item in rawList) {
        final loc = _LiveLocation.fromJson(item as Map<String, dynamic>);
        updated[loc.salesmanName] = loc;
      }

      if (mounted) {
        setState(() => _liveLocations = updated);
        debugPrint('📍 Live: fetched ${updated.length} salesmen positions');
      }
    } catch (e) {
      debugPrint('📍 Live fetch error: $e');
      // Silent fail — will retry next minute
    }
  }

  // ──────────────────────────────────────────────
  // Existing: Fetch matched visits + salesman list
  // ──────────────────────────────────────────────
  Future<void> _fetchAndBuild() async {
    setState(() => loading = true);

    final role = widget.user["role"].toString().toLowerCase();
    final userName = widget.user["name"].toString();
    final userSegment = widget.user["segment"].toString().toUpperCase();

    final results = await Future.wait([
      ApiService.getLogs(),
      UserService().getUsers(),
    ]);

    final rawResponse = results[0] as Map<String, dynamic>;
    final List<UserModel> allUsersList = results[1] as List<UserModel>;
    final List<dynamic> rawVisits = rawResponse["visits"] ?? [];

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
    _buildSalesmanList(allUsersList);
  }

  double? _parseCoord(dynamic val) {
    if (val == null) return null;
    return double.tryParse(val.toString());
  }

  void _buildSalesmanList(List<UserModel> allUsersList) {
    final role = widget.user["role"].toString().toLowerCase();
    final userSegment = widget.user["segment"].toString().toUpperCase();

    if (role == "salesman") {
      selectedSalesman = widget.user["name"].toString();
      salesmanList = [];
    } else if (role == "manager") {
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

    _applyFilters();
  }

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

  void _fitBounds() {
    // Collect all points: route + live locations
    final allPoints = [
      ...routePoints,
      if (_showLive) ..._liveLocations.values.map((l) => LatLng(l.lat, l.lng)),
    ];

    if (allPoints.isEmpty) return;
    if (allPoints.length == 1) {
      _mapController.move(allPoints.first, 15);
      return;
    }
    final lats = allPoints.map((p) => p.latitude);
    final lngs = allPoints.map((p) => p.longitude);
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
  // LIVE: Build live location markers
  // ──────────────────────────────────────────────
  List<Marker> _buildLiveMarkers() {
    if (!_showLive) return [];

    final role = widget.user['role'].toString().toLowerCase();
    // For salesman role: only show their own dot
    // For manager/master: show all live salesmen
    final liveToShow = role == 'salesman'
        ? _liveLocations.values
            .where((l) =>
                l.salesmanName.toLowerCase() ==
                widget.user['name'].toString().toLowerCase())
            .toList()
        : _liveLocations.values.toList();

    return liveToShow.map((loc) {
      final isStale = loc.isStale;
      final dotColor =
          isStale ? Colors.grey.shade500 : const Color(0xFF00C853); // green

      return Marker(
        point: LatLng(loc.lat, loc.lng),
        width: 56,
        height: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Name tag above dot
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isStale ? Colors.grey.shade700 : const Color(0xFF003300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                loc.salesmanName.split(' ').first, // first name only
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            // Animated pulsing dot
            _PulsingDot(color: dotColor, stale: isStale),
            // "x min ago" label
            Text(
              isStale ? '${loc.minutesAgo}m ago' : 'Live',
              style: TextStyle(
                  fontSize: 8,
                  color: isStale ? Colors.grey : const Color(0xFF00C853),
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }).toList();
  }

  // ──────────────────────────────────────────────
  // Existing: Matched-visit markers
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
  // Filter bar (unchanged + live toggle)
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
          // Date chips + Live toggle in same row
          Row(
            children: [
              ...dateOptions.map((opt) {
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
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
              }),
              const Spacer(),
              // ── Live toggle (NEW) ──
              GestureDetector(
                onTap: () => setState(() => _showLive = !_showLive),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showLive
                        ? const Color(0xFF00C853)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      Icons.radio_button_checked,
                      size: 12,
                      color: _showLive ? Colors.white : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              _showLive ? Colors.white : Colors.grey.shade600),
                    ),
                  ]),
                ),
              ),
            ],
          ),

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
                            const Spacer(),
                            // Live status indicator next to name
                            if (_liveLocations.containsKey(name))
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _liveLocations[name]!.isStale
                                      ? Colors.grey
                                      : const Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                ),
                              ),
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

  Widget _buildSummaryStrip() {
    final liveCount = _showLive ? _liveLocations.length : 0;
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
            "${filteredLogs.length} visit${filteredLogs.length != 1 ? 's' : ''}  •  $selectedDateFilter"
            "${liveCount > 0 ? '  •  $liveCount online' : ''}",
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
        if (routePoints.isNotEmpty || _liveLocations.isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: routePoints.isNotEmpty
                      ? routePoints.first
                      : _liveLocations.isNotEmpty
                          ? LatLng(
                              _liveLocations.values.first.lat,
                              _liveLocations.values.first.lng,
                            )
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
                  // Matched visits polyline
                  if (routePoints.length > 1)
                    PolylineLayer(polylines: [
                      Polyline(
                          points: routePoints,
                          strokeWidth: 3.5,
                          color: const Color(0xFF005BBB)),
                    ]),
                  // All markers: visits + live (live on top)
                  MarkerLayer(
                    markers: [
                      ..._buildMarkers(),
                      ..._buildLiveMarkers(), // live dots on top
                    ],
                  ),
                ],
              ),
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
                      const SizedBox(height: 6),
                      _legendDot(const Color(0xFF00C853), "Live"), // NEW
                    ],
                  ),
                ),
              _buildInfoCard(),
              if (filteredLogs.isEmpty && _liveLocations.isEmpty)
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

// ──────────────────────────────────────────────────────────
// Pulsing green dot widget for live markers
// ──────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  final bool stale;
  const _PulsingDot({required this.color, required this.stale});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _anim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    if (!widget.stale) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _anim,
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}
