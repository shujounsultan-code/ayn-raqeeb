
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_session.dart';
import 'dart:math' as math;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  void _showPopup(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
  List<Map<String, dynamic>> students = [];
  LatLng? busLocation;
  double? busAccuracy;
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? driverData;
  final LatLng schoolLocation = const LatLng(21.4858, 40.5444); // موقع المدرسة (مثال: جدة)
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    driverData = DriverSession.currentDriver;
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final busNumber =
          driverData != null ? driverData!['bus_number']?.toString().trim() : null;
      final schoolId =
          driverData != null ? driverData!['school_id']?.toString().trim() : null;
      // جلب بيانات الطلاب المرتبطين بنفس المدرسة، ثم فلترتهم حسب رقم الباص
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .where('school_id', isEqualTo: schoolId ?? '')
          .get();
      final List<Map<String, dynamic>> loadedStudents = [];
      final List<Map<String, dynamic>> studentsWithLocation = [];
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final sBus = (data['bus'] ?? '').toString().trim();
        if ((busNumber ?? '').isEmpty || sBus != (busNumber ?? '')) {
          continue;
        }
        loadedStudents.add({
          'name': data['name'] ?? '',
          'lat': data['home_lat'],
          'lng': data['home_lng'],
          'grade': data['grade'] ?? '',
        });
        if (data['home_lat'] is num && data['home_lng'] is num) {
          studentsWithLocation.add({
            'name': data['name'] ?? '',
            'lat': data['home_lat'],
            'lng': data['home_lng'],
            'grade': data['grade'] ?? '',
          });
        }
      }
      studentsWithLocation.sort((a, b) {
        final d1 = Distance().as(
          LengthUnit.Kilometer,
          schoolLocation,
          LatLng(
            (a['lat'] as num).toDouble(),
            (a['lng'] as num).toDouble(),
          ),
        );
        final d2 = Distance().as(
          LengthUnit.Kilometer,
          schoolLocation,
          LatLng(
            (b['lat'] as num).toDouble(),
            (b['lng'] as num).toDouble(),
          ),
        );
        return d1.compareTo(d2);
      });
      // جلب موقع الحافلة
      LatLng? busLoc;
      double? accuracy;
      final busDocId = ((schoolId ?? '').isNotEmpty && (busNumber ?? '').isNotEmpty)
          ? '${schoolId}_$busNumber'
          : (busNumber ?? '');
      DocumentSnapshot<Map<String, dynamic>> busSnap;
      if (busDocId.isNotEmpty) {
        busSnap = await FirebaseFirestore.instance
            .collection('bus_locations')
            .doc(busDocId)
            .get();
      } else {
        busSnap = await FirebaseFirestore.instance
            .collection('bus_locations')
            .doc(busNumber)
            .get();
      }
      if (!busSnap.exists && (busNumber ?? '').isNotEmpty) {
        busSnap = await FirebaseFirestore.instance
            .collection('bus_locations')
            .doc(busNumber)
            .get();
      }
      if (busSnap.exists) {
        final data = busSnap.data();
        if (data != null && data['lat'] is num && data['lng'] is num) {
          busLoc = LatLng(
            (data['lat'] as num).toDouble(),
            (data['lng'] as num).toDouble(),
          );
          accuracy = (data['accuracy'] as num?)?.toDouble() ?? 50.0;
        }
      }
      setState(() {
        students = loadedStudents;
        busLocation = busLoc ?? schoolLocation;
        busAccuracy = accuracy ?? 50.0;
        isLoading = false;
      });
      // fitBounds بعد التحميل
      if (studentsWithLocation.isNotEmpty) {
        final points = [
          schoolLocation,
          ...studentsWithLocation.map(
            (s) => LatLng(
              (s['lat'] as num).toDouble(),
              (s['lng'] as num).toDouble(),
            ),
          )
        ];
        var bounds = LatLngBounds.fromPoints(points);
        Future.delayed(const Duration(milliseconds: 300), () {
          _mapController.fitBounds(bounds, options: const FitBoundsOptions(padding: EdgeInsets.all(20)));
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في جلب البيانات: $e';
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final studentsWithLocation = students
        .where((s) => s['lat'] is num && s['lng'] is num)
        .toList();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // الشريط العلوي (لا يتغير)
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/logobg.png',
                              width: 60,
                              height: 60,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
                            ),
                            const SizedBox(height: 1),
                            const Text('عين رقيب', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B7C80), fontSize: 13)),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                  // الخريطة
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: busLocation ?? schoolLocation,
                            initialZoom: 13,
                            interactionOptions: const InteractionOptions(enableScrollWheel: false, enableMultiFingerGestureRace: false),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.example.ayn_raqeeb_app',
                            ),
                            // Polyline route: من المدرسة إلى كل طالبة بالترتيب (متقطع)
                            if (studentsWithLocation.isNotEmpty)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      schoolLocation,
                                      ...studentsWithLocation.map(
                                        (s) => LatLng(
                                          (s['lat'] as num).toDouble(),
                                          (s['lng'] as num).toDouble(),
                                        ),
                                      )
                                    ],
                                    color: const Color(0xFF1B7C80),
                                    strokeWidth: 4,
                                    isDotted: true,
                                    borderColor: Colors.white,
                                    borderStrokeWidth: 0.5,
                                  ),
                                ],
                              ),
                            // دائرة دقة GPS حول الحافلة (CircleLayer)
                            if (busLocation != null && busAccuracy != null)
                              CircleLayer(
                                circles: [
                                  CircleMarker(
                                    point: busLocation!,
                                    color: const Color(0xFF1B7C80).withOpacity(0.1),
                                    borderStrokeWidth: 1,
                                    borderColor: const Color(0xFF1B7C80),
                                    radius: busAccuracy! / 2,
                                  ),
                                ],
                              ),
                            // Markers: المدرسة، الحافلة، الطالبات
                            MarkerLayer(
                              markers: [
                                // Marker المدرسة
                                Marker(
                                  width: 32,
                                  height: 32,
                                  point: schoolLocation,
                                  child: GestureDetector(
                                    onTap: () => _showPopup(context, '🏫 المدرسة'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1B7C80),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF1B7C80).withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: const Center(child: Text('🏫', style: TextStyle(fontSize: 18, color: Colors.white))),
                                    ),
                                  ),
                                ),
                                // Marker الحافلة
                                if (busLocation != null)
                                  Marker(
                                    width: 36,
                                    height: 36,
                                    point: busLocation!,
                                    child: GestureDetector(
                                      onTap: () => _showPopup(context, '🚌 حافلة 26'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFdc2626),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFFdc2626).withOpacity(0.3),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: const Center(child: Text('🚌', style: TextStyle(fontSize: 18, color: Colors.white))),
                                      ),
                                    ),
                                  ),
                                // Markers الطالبات
                                ...studentsWithLocation.map((s) => Marker(
                                      width: 24,
                                      height: 24,
                                      point: LatLng(
                                        (s['lat'] as num).toDouble(),
                                        (s['lng'] as num).toDouble(),
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _showPopup(context, '📍 ${s['name']}'),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD97706),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFD97706).withOpacity(0.3),
                                                blurRadius: 6,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: const Center(child: Text('📍', style: TextStyle(fontSize: 13, color: Colors.white))),
                                        ),
                                      ),
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // شريط معلومات الطريق (وقت، مسافة، عدد الطالبات)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEEEDED)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _routeStat('⏱️', 'الوقت المتبقي', _estimateTime()),
                        _routeStat('📏', 'المسافة', _estimateDistance()),
                        _routeStat('👧', 'على الباص', students.length.toString()),
                      ],
                    ),
                  ),
                  // قائمة الطالبات
                  Expanded(
                    child: students.isEmpty
                        ? const Center(child: Text('لا توجد طالبات'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            itemCount: students.length,
                            itemBuilder: (context, i) {
                              final s = students[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      margin: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF3E6F9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.person, size: 32, color: Colors.grey),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                        child: Text(
                                          'الاسم : ${s['name']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _routeStat(String icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B7C80))),
        const SizedBox(height: 4),
        Text('$icon $label', style: const TextStyle(fontSize: 11, color: Color(0xFFb0b8c1))),
      ],
    );
  }

  String _estimateTime() {
    // تقدير الوقت (مطابق للـ JS: دقيقة لكل طالبة + 0.5 دقيقة/كم، يبدأ من المدرسة)
    final locStudents =
        students.where((s) => s['lat'] is num && s['lng'] is num).toList();
    if (locStudents.isEmpty) return '--';
    double totalDist = 0;
    LatLng prev = schoolLocation;
    for (var s in locStudents) {
      final lat = (s['lat'] as num).toDouble();
      final lng = (s['lng'] as num).toDouble();
      final p = LatLng(lat, lng);
      totalDist += Distance().as(LengthUnit.Kilometer, prev, p);
      prev = p;
    }
    final eta = math.max(5, (locStudents.length * 1 + totalDist * 0.5).round());
    return '$eta د';
  }

  String _estimateDistance() {
    final locStudents =
        students.where((s) => s['lat'] is num && s['lng'] is num).toList();
    if (locStudents.isEmpty) return '--';
    double totalDist = 0;
    LatLng prev = schoolLocation;
    for (var s in locStudents) {
      final lat = (s['lat'] as num).toDouble();
      final lng = (s['lng'] as num).toDouble();
      final p = LatLng(lat, lng);
      totalDist += Distance().as(LengthUnit.Kilometer, prev, p);
      prev = p;
    }
    return '${totalDist.toStringAsFixed(1)} كم';
  }
}

