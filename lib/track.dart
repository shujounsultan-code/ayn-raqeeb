import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

// ─── Models ───────────────────────────────────────────────────────────────────

class BusLocation {
  final String busNumber;
  final String schoolId;
  final double lat;
  final double lng;
  final int accuracy;
  final List<TrailPoint> trail;

  BusLocation({
    required this.busNumber,
    required this.schoolId,
    required this.lat,
    required this.lng,
    required this.accuracy,
    required this.trail,
  });

  factory BusLocation.fromFirestore(Map<String, dynamic> data) {
    final trailList = (data['trail'] as List<dynamic>? ?? [])
        .map(
          (t) => TrailPoint(
            lat: (t['lat'] as num).toDouble(),
            lng: (t['lng'] as num).toDouble(),
          ),
        )
        .toList();
    return BusLocation(
      busNumber: data['bus_number']?.toString() ?? '',
      schoolId: data['school_id']?.toString() ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      accuracy: (data['accuracy'] as num?)?.toInt() ?? 0,
      trail: trailList,
    );
  }
}

class TrailPoint {
  final double lat;
  final double lng;
  TrailPoint({required this.lat, required this.lng});
}

class BusInfo {
  final String id;
  final String busNumber;
  final String schoolId;
  final int availableSeats;
  final int capacity;

  BusInfo({
    required this.id,
    required this.busNumber,
    required this.schoolId,
    required this.availableSeats,
    required this.capacity,
  });

  factory BusInfo.fromFirestore(String id, Map<String, dynamic> data) {
    return BusInfo(
      id: id,
      busNumber: data['bus_number']?.toString() ?? '',
      schoolId: data['school_id']?.toString() ?? '',
      availableSeats: (data['available_seats'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 0,
    );
  }
}

class DriverInfo {
  final String busNumber;
  final String driverName;
  final String phoneNumber;
  final String driverId;

  DriverInfo({
    required this.busNumber,
    required this.driverName,
    required this.phoneNumber,
    required this.driverId,
  });

  factory DriverInfo.fromFirestore(Map<String, dynamic> data) {
    return DriverInfo(
      busNumber: data['bus_number']?.toString() ?? '',
      driverName: data['driver_name']?.toString() ?? '',
      phoneNumber: data['phone_number']?.toString() ?? '',
      driverId: data['driver_id']?.toString() ?? '',
    );
  }
}

// ─── Distance Helper ──────────────────────────────────────────────────────────

double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const R = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String _formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} م';
  return '${(meters / 1000).toStringAsFixed(1)} كم';
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class LiveTrackingScreen extends StatefulWidget {
  final String schoolId;
  const LiveTrackingScreen({super.key, required this.schoolId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final MapController _mapController = MapController();

  Stream<QuerySnapshot>? _busLocationsStream;
  Stream<QuerySnapshot>? _busInfoStream;
  Stream<QuerySnapshot>? _driversStream;

  String? _selectedBusNumber;
  Map<String, BusLocation> _locations = {};
  List<BusInfo> _buses = [];
  Map<String, DriverInfo> _drivers = {};

  // TODO: استبدل بموقع حقيقي من geolocator
  final LatLng? _userLocation = const LatLng(26.416019, 50.027927);

  @override
  void initState() {
    super.initState();
    _busLocationsStream = FirebaseFirestore.instance
        .collection('bus_locations')
        .where('school_id', isEqualTo: widget.schoolId)
        .snapshots();
    _busInfoStream = FirebaseFirestore.instance
        .collection('buses')
        .where('school_id', isEqualTo: widget.schoolId)
        .snapshots();
    _driversStream = FirebaseFirestore.instance
        .collection('drivers')
        .where('school_id', isEqualTo: widget.schoolId)
        .snapshots();
  }

  void _selectBus(String busNumber) {
    setState(() {
      _selectedBusNumber = _selectedBusNumber == busNumber ? null : busNumber;
    });
    final loc = _locations[busNumber];
    if (loc != null && _selectedBusNumber != null) {
      _mapController.move(LatLng(loc.lat, loc.lng), 16.0);
    }
  }

  Future<void> _callDriver(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  String? _distanceLabel(BusLocation bus) {
    if (_userLocation == null) return null;
    final m = _haversineMeters(
      _userLocation!.latitude,
      _userLocation!.longitude,
      bus.lat,
      bus.lng,
    );
    return _formatDistance(m);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        appBar: _buildAppBar(),
        body: StreamBuilder<QuerySnapshot>(
          stream: _driversStream,
          builder: (context, driverSnapshot) {
            if (driverSnapshot.hasData) {
              _drivers = {};
              for (final doc in driverSnapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                try {
                  final driver = DriverInfo.fromFirestore(data);
                  _drivers[driver.busNumber] = driver;
                } catch (_) {}
              }
            }
            return StreamBuilder<QuerySnapshot>(
              stream: _busLocationsStream,
              builder: (context, locSnapshot) {
                if (locSnapshot.hasData) {
                  _locations = {};
                  for (final doc in locSnapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    try {
                      final loc = BusLocation.fromFirestore(data);
                      _locations[loc.busNumber] = loc;
                    } catch (_) {}
                  }
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: _busInfoStream,
                  builder: (context, busSnapshot) {
                    if (busSnapshot.hasData) {
                      _buses = busSnapshot.data!.docs.map((doc) {
                        return BusInfo.fromFirestore(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        );
                      }).toList();
                    }
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMapCard(),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                const Text(
                                  'الباصات',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF173B3D),
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE1F5EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${_buses.isNotEmpty ? _buses.length : _locations.length} باص',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF0F6E56),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildBusCards(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          Icon(
            Icons.directions_bus_rounded,
            color: Color(0xFF1B7C80),
            size: 22,
          ),
          SizedBox(width: 8),
          Text(
            'خريطة التتبع',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF173B3D),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF173B3D)),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.only(left: 14, top: 10, bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE1F5EE),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.circle, color: Color(0xFF1D9E75), size: 8),
              SizedBox(width: 4),
              Text(
                'مباشر',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0F6E56),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: Colors.black12),
      ),
    );
  }

  Widget _buildMapCard() {
    final markers = <Marker>[];
    final polylines = <Polyline>[];

    for (final entry in _locations.entries) {
      final busNumber = entry.key;
      final loc = entry.value;
      final isSelected = _selectedBusNumber == busNumber;

      if (loc.trail.isNotEmpty) {
        final points = [
          LatLng(loc.lat, loc.lng),
          ...loc.trail.map((t) => LatLng(t.lat, t.lng)),
        ];

        // الخط الكامل (فاتح)
        polylines.add(
          Polyline(
            points: points,
            color: isSelected
                ? const Color(0xFF1D9E75).withOpacity(0.35)
                : const Color(0xFF1D9E75).withOpacity(0.2),
            strokeWidth: isSelected ? 3.0 : 2.0,
          ),
        );

        // آخر 5 نقاط (غامق = أحدث مسار)
        final recent = points.take(math.min(6, points.length)).toList();
        polylines.add(
          Polyline(
            points: recent,
            color: isSelected
                ? const Color(0xFF1D9E75)
                : const Color(0xFF1D9E75).withOpacity(0.7),
            strokeWidth: isSelected ? 4.5 : 3.0,
          ),
        );
      }

      markers.add(
        Marker(
          point: LatLng(loc.lat, loc.lng),
          width: 64,
          height: 72,
          child: GestureDetector(
            onTap: () => _selectBus(busNumber),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF185FA5)
                          : Colors.black12,
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    'باص $busNumber',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF185FA5)
                          : const Color(0xFF173B3D),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 42 : 36,
                  height: isSelected ? 42 : 36,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF185FA5)
                        : const Color(0xFF1B7C80),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isSelected
                                    ? const Color(0xFF185FA5)
                                    : const Color(0xFF1B7C80))
                                .withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_bus,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    const defaultCenter = LatLng(26.416019, 50.027927);

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: defaultCenter,
                initialZoom: 14.5,
                minZoom: 10,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
            if (_selectedBusNumber != null)
              Positioned(
                top: 10,
                left: 10,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedBusNumber = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: Color(0xFF173B3D),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'إلغاء',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF173B3D),
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

  Widget _buildBusCards() {
    if (_buses.isEmpty && _locations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(
            color: Color(0xFF1B7C80),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final items = _buses.isNotEmpty
        ? _buses.map((b) => _buildBusCard(b)).toList()
        : _locations.values.map((l) => _buildBusCardFromLocation(l)).toList();

    return Column(
      children: items
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          )
          .toList(),
    );
  }

  Widget _buildBusCard(BusInfo bus) {
    final isSelected = _selectedBusNumber == bus.busNumber;
    final hasLocation = _locations.containsKey(bus.busNumber);
    final driver = _drivers[bus.busNumber];
    final loc = _locations[bus.busNumber];
    final distance = loc != null ? _distanceLabel(loc) : null;

    return GestureDetector(
      onTap: () => _selectBus(bus.busNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F8F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B7C80)
                : const Color(0xFFE8EEEE),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1B7C80)
                        : const Color(0xFFEAF7F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: isSelected ? Colors.white : const Color(0xFF1B7C80),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'باص ${bus.busNumber}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF1B7C80)
                              : const Color(0xFF173B3D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.event_seat_rounded,
                            size: 12,
                            color: Color(0xFF888780),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${bus.availableSeats} / ${bus.capacity} مقعد',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888780),
                            ),
                          ),
                          // ── المسافة مدمجة في نفس الصف ──
                          if (distance != null) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '·',
                              style: TextStyle(color: Color(0xFF888780)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.near_me_rounded,
                              size: 12,
                              color: Color(0xFF1B7C80),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distance,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B7C80),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: hasLocation
                        ? const Color(0xFFE1F5EE)
                        : const Color(0xFFF1EFE8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 6,
                        color: hasLocation
                            ? const Color(0xFF0F6E56)
                            : const Color(0xFF888780),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasLocation ? 'نشط' : 'غير متصل',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: hasLocation
                              ? const Color(0xFF0F6E56)
                              : const Color(0xFF5F5E5A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (driver != null) ...[
              const SizedBox(height: 12),
              _buildDriverRow(driver, isSelected),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBusCardFromLocation(BusLocation loc) {
    final isSelected = _selectedBusNumber == loc.busNumber;
    final driver = _drivers[loc.busNumber];
    final distance = _distanceLabel(loc);

    return GestureDetector(
      onTap: () => _selectBus(loc.busNumber),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F8F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1B7C80)
                : const Color(0xFFE8EEEE),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1B7C80)
                        : const Color(0xFFEAF7F7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: isSelected ? Colors.white : const Color(0xFF1B7C80),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'باص ${loc.busNumber}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFF1B7C80)
                              : const Color(0xFF173B3D),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Color(0xFF888780),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${loc.lat.toStringAsFixed(4)}, ${loc.lng.toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888780),
                            ),
                          ),
                          if (distance != null) ...[
                            const SizedBox(width: 8),
                            const Text(
                              '·',
                              style: TextStyle(color: Color(0xFF888780)),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.near_me_rounded,
                              size: 12,
                              color: Color(0xFF1B7C80),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              distance,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B7C80),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: Color(0xFF0F6E56)),
                      SizedBox(width: 4),
                      Text(
                        'نشط',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F6E56),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (driver != null) ...[
              const SizedBox(height: 12),
              _buildDriverRow(driver, isSelected),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDriverRow(DriverInfo driver, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.7)
            : const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EFEF), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F6F7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                driver.driverName.isNotEmpty ? driver.driverName[0] : '؟',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B7C80),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.driverName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF173B3D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  driver.phoneNumber,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF888780),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _callDriver(driver.phoneNumber),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1B7C80),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.call_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
