import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../parent_session.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => BusTrackingScreenState();
}

class BusTrackingScreenState extends State<BusTrackingScreen> {
  static const Color teal = Color(0xFF1B7C80);
  static const Color darkBlue = Color(0xFF0B4C75);

  static const LatLng defaultLocation = LatLng(24.7136, 46.6753); // الرياض

  int currentIndex = 1;
  LatLng? busLocation;
  LatLng? studentHomeLocation;
  List<Map<String, dynamic>> trail = [];
  List<LatLng> routeToStudent = [];
  MapController _mapController = MapController();
  StreamSubscription<DocumentSnapshot>? _busLocationSubscription;
  StreamSubscription<QuerySnapshot>? _boardingSubscription;
  bool isStudentOnBus = false;
  String? activeBusDocId;
  bool _mapReady = false;

  // بيانات الرحلة والطلاب
  List<Map<String, dynamic>> studentsOnRoute = [];
  Map<String, dynamic>? tripData;
  double estimatedSpeed = 40.0; // كم/ساعة - سرعة متوسطة للحافلة

  // حالة الطالب الحالية
  String currentStatus = 'at_school'; // at_school, on_bus, on_way, arrived

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchStudentHomeLocation();
    _fetchStudentsOnRoute();
    _startBoardingListener();
  }

  @override
  void dispose() {
    _busLocationSubscription?.cancel();
    _boardingSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchStudentHomeLocation() async {
    final studentDocId = ParentSession.studentDocId;
    if (studentDocId == null || studentDocId.isEmpty) {
      debugPrint('BusTrackingScreen: لا يوجد معرف الطالب');
      return;
    }

    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(studentDocId)
          .get();

      if (!studentDoc.exists) {
        debugPrint('BusTrackingScreen: الطالب غير موجود');
        return;
      }

      final data = studentDoc.data();
      if (data == null) return;

      final homeLat = data['home_lat'] as double?;
      final homeLng = data['home_lng'] as double?;

      if (homeLat != null && homeLng != null) {
        setState(() {
          studentHomeLocation = LatLng(homeLat, homeLng);
        });
        debugPrint('BusTrackingScreen: موقع بيت الطالب: $homeLat, $homeLng');
        // جلب المسار إذا كان موقع الباص متوفراً
        if (busLocation != null) {
          _fetchRouteToStudent();
        }
      }
    } catch (e) {
      debugPrint('BusTrackingScreen: خطأ في جلب موقع بيت الطالب: $e');
    }
  }

  Future<void> _fetchStudentsOnRoute() async {
    final schoolId = ParentSession.schoolIdFromParent;
    final busNumber = ParentSession.studentBusOnParent;

    if (schoolId == null || schoolId.isEmpty || busNumber == null || busNumber.isEmpty) {
      debugPrint('BusTrackingScreen: لا يوجد معرف المدرسة أو رقم الحافلة');
      return;
    }

    try {
      final studentsQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('school_id', isEqualTo: schoolId)
          .where('bus', isEqualTo: busNumber)
          .get();

      final students = studentsQuery.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name']?.toString() ?? '',
          'home_lat': data['home_lat'] as double?,
          'home_lng': data['home_lng'] as double?,
          'postal_code': data['postal_code']?.toString() ?? '',
        };
      }).toList();

      // ترتيب الطلاب حسب المسافة من موقع الحافلة الحالي
      if (busLocation != null) {
        students.sort((a, b) {
          final latA = a['home_lat'] as double?;
          final lngA = a['home_lng'] as double?;
          final latB = b['home_lat'] as double?;
          final lngB = b['home_lng'] as double?;

          if (latA == null || lngA == null) return 1;
          if (latB == null || lngB == null) return -1;

          final distanceA = _calculateDistance(
            busLocation!,
            LatLng(latA, lngA),
          );
          final distanceB = _calculateDistance(
            busLocation!,
            LatLng(latB, lngB),
          );

          return distanceA.compareTo(distanceB);
        });
      }

      setState(() {
        studentsOnRoute = students;
      });

      debugPrint('BusTrackingScreen: تم جلب ${students.length} طالب على الحافلة (مرتبة حسب المسافة)');
    } catch (e) {
      debugPrint('BusTrackingScreen: خطأ في جلب الطلاب: $e');
    }
  }

  Future<void> _fetchRouteToStudent() async {
    if (busLocation == null || studentHomeLocation == null) return;

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${busLocation!.longitude},${busLocation!.latitude};'
        '${studentHomeLocation!.longitude},${studentHomeLocation!.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final coordinates = route['geometry']['coordinates'] as List;

          final routePoints = coordinates.map((coord) {
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();

          setState(() {
            routeToStudent = routePoints;
          });
          debugPrint('BusTrackingScreen: تم جلب المسار بنجاح (${routePoints.length} نقطة)');
        }
      }
    } catch (e) {
      debugPrint('BusTrackingScreen: خطأ في جلب المسار: $e');
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // كم
    final double lat1 = start.latitude * (math.pi / 180);
    final double lat2 = end.latitude * (math.pi / 180);
    final double deltaLat = (end.latitude - start.latitude) * (math.pi / 180);
    final double deltaLng = (end.longitude - start.longitude) * (math.pi / 180);

    final double a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLng / 2), 2);
    final double c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  String _calculateETA(LatLng? studentLocation) {
    if (busLocation == null || studentLocation == null) return '--';

    final distance = _calculateDistance(busLocation!, studentLocation);
    final timeInHours = distance / estimatedSpeed;
    final timeInMinutes = (timeInHours * 60).round();

    if (timeInMinutes < 1) return 'أقل من دقيقة';
    if (timeInMinutes == 1) return 'دقيقة واحدة';
    if (timeInMinutes < 60) return '$timeInMinutes دقيقة';

    final hours = timeInMinutes ~/ 60;
    final remainingMinutes = timeInMinutes % 60;
    if (remainingMinutes == 0) return '$hours ساعة';
    return '$hours ساعة و$remainingMinutes دقيقة';
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getArrivalTime(LatLng? studentLocation) {
    if (busLocation == null || studentLocation == null) return '--';

    final distance = _calculateDistance(busLocation!, studentLocation);
    final timeInHours = distance / estimatedSpeed;
    final timeInMinutes = (timeInHours * 60).round();

    final arrivalTime = DateTime.now().add(Duration(minutes: timeInMinutes));
    final hour = arrivalTime.hour.toString().padLeft(2, '0');
    final minute = arrivalTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getSchoolDepartureTime() {
    // وقت الخروج من المدرسة (يمكن تعديله أو جلبه من البيانات)
    // سنفترض أن وقت الخروج هو 12:40
    return '12:40';
  }

  void _updateStudentStatus() {
    if (busLocation == null || studentHomeLocation == null) return;

    final distance = _calculateDistance(busLocation!, studentHomeLocation!);

    // تحديد حالة الطالب بناءً على المسافة
    if (distance < 0.1) {
      // أقل من 100 متر - وصل للمنزل
      setState(() {
        currentStatus = 'arrived';
      });
    } else if (distance < 2.0) {
      // أقل من 2 كم - في الطريق للمنزل
      setState(() {
        currentStatus = 'on_way';
      });
    } else {
      // في الحافلة
      setState(() {
        currentStatus = 'on_bus';
      });
    }
  }

  void _startBoardingListener() {
    final studentDocId = ParentSession.studentDocId;
    if (studentDocId == null) return;

    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6));

    // الاستماع المباشر لأحداث الصعود (Boarding Events)
    _boardingSubscription = FirebaseFirestore.instance
        .collection('board_events')
        .where('student_doc_id', isEqualTo: studentDocId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      
      if (snapshot.docs.isNotEmpty) {
        // ترتيب يدوياً لضمان الدقة وتجنب مشاكل الفهرسة (Indexing)
        final docs = snapshot.docs.toList();
        docs.sort((a, b) {
          final ta = a.data() as Map<String, dynamic>;
          final tb = b.data() as Map<String, dynamic>;
          
          // استخدام created_at_ms كمفتاح ترتيب أدق في حال كان created_at لم يطبق بعد
          final ma = ta['created_at_ms'] as num? ?? 0;
          final mb = tb['created_at_ms'] as num? ?? 0;
          return mb.compareTo(ma);
        });

        final data = docs.first.data() as Map<String, dynamic>;
        final createdAt = data['created_at'] as Timestamp?;
        final createdAtMs = data['created_at_ms'] as num?;
        
        DateTime? eventTime;
        if (createdAt != null) {
          eventTime = createdAt.toDate();
        } else if (createdAtMs != null) {
          eventTime = DateTime.fromMillisecondsSinceEpoch(createdAtMs.toInt());
        }
        
        // التحقق من أن الحدث حديث (خلال آخر 8 ساعات)
        if (eventTime != null && 
            DateTime.now().difference(eventTime).inHours < 8) {
          final busNumber = data['bus_number']?.toString();
          final schoolId = data['school_id']?.toString();

          if (busNumber != null && schoolId != null) {
            final newBusDocId = '${schoolId}_$busNumber';
            
            // تحديث الحالة حتى لو كان نفس الباص لضمان استمرار التتبع
            setState(() {
              isStudentOnBus = true;
              currentStatus = 'on_bus';
              activeBusDocId = newBusDocId;
            });
            
            // إعادة جلب موقع منزل الطالب للتأكد من تحديثه (خاصة إذا تم تحديثه من الرمز البريدي عند المسح)
            _fetchStudentHomeLocation();
            _listenToBusLocation(newBusDocId);
            return;
          }
        }
      }
      
      setState(() {
        isStudentOnBus = false;
        busLocation = null;
        currentStatus = 'waiting';
        activeBusDocId = null;
      });
    });
  }

  void _listenToBusLocation(String busDocId) {
    _busLocationSubscription?.cancel();
    debugPrint('BusTrackingScreen: تتبع الحافلة المحددة للطالب: $busDocId');

    _busLocationSubscription = FirebaseFirestore.instance
        .collection('bus_locations')
        .doc(busDocId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final lat = data['lat'] as double?;
          final lng = data['lng'] as double?;
          final trailData = data['trail'] as List<dynamic>?;

          if (lat != null && lng != null) {
            setState(() {
              busLocation = LatLng(lat, lng);
              if (trailData != null) {
                trail = List<Map<String, dynamic>>.from(
                  trailData.map((e) => Map<String, dynamic>.from(e)),
                );
              }
            });
            if (_mapReady) {
              _mapController.move(LatLng(lat, lng), 16);
            }
            _fetchRouteToStudent();
            _updateStudentStatus();
          }
        }
      }
    });
  }

  void _startBusLocationTracking() {
    // تم استبدالها بـ _startBoardingListener لضمان الأمان
  }

  void _toggleMapExpanded() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenMap(
          busLocation: busLocation,
          studentHomeLocation: studentHomeLocation,
          trail: trail,
          routeToStudent: routeToStudent,
          defaultLocation: defaultLocation,
          teal: teal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh, color: teal),
                        onPressed: () {
                          _startBoardingListener();
                          _fetchStudentHomeLocation();
                          showMessage('جاري تحديث البيانات...');
                        },
                      ),
                      InkWell(
                        onTap: () {
                          showMessage('فتح صفحة التنبيهات');
                        },
                        child: const Icon(
                          Icons.notifications_none,
                          size: 31,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () {
                          showMessage('فتح صفحة الرسائل');
                        },
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 30,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logobg.png',
                        width: 90,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -8),
                        child: const Text(
                          'عين رقيب',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  TimelineRow(
                    time: _getSchoolDepartureTime(),
                    text: 'إنتهاء اليوم الدراسي',
                    first: true,
                    active: currentStatus == 'at_school',
                  ),
                  TimelineRow(
                    time: _getCurrentTime(),
                    text: 'موقع الحافلة الحالي',
                    active: currentStatus == 'on_bus',
                  ),
                  TimelineRow(
                    time: _calculateETA(studentHomeLocation),
                    text: 'متبقي ${_calculateETA(studentHomeLocation)} لوصول الطالب للمنزل',
                    active: currentStatus == 'on_way',
                  ),
                  TimelineRow(
                    time: _getArrivalTime(studentHomeLocation),
                    text: 'قد وصل الطالب للمنزل',
                    last: true,
                    active: currentStatus == 'arrived',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 34),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                children: [
                  StepItem(
                    icon: Icons.apartment,
                    time: _getSchoolDepartureTime(),
                    active: currentStatus == 'at_school',
                  ),
                  const StepConnector(),
                  StepItem(
                    icon: Icons.accessible,
                    time: _getCurrentTime(),
                    active: currentStatus == 'on_bus',
                  ),
                  const StepConnector(),
                  StepItem(
                    icon: Icons.hourglass_empty,
                    time: _calculateETA(studentHomeLocation),
                    active: currentStatus == 'on_way',
                  ),
                  const StepConnector(),
                  StepItem(
                    icon: Icons.home,
                    time: _getArrivalTime(studentHomeLocation),
                    active: currentStatus == 'arrived',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: busLocation ?? defaultLocation,
                              initialZoom: 15,
                              onMapReady: () {
                                setState(() {
                                  _mapReady = true;
                                });
                                if (busLocation != null) {
                                  _mapController.move(busLocation!, 16);
                                }
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                                userAgentPackageName: 'com.appaynraqeeb.ayn_raqeeb',
                              ),
                              // عرض المسار إلى بيت الطالب
                              if (routeToStudent.isNotEmpty)
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: routeToStudent,
                                      strokeWidth: 5.0,
                                      color: Colors.blue.withOpacity(0.8),
                                    ),
                                  ],
                                ),
                              MarkerLayer(
                                markers: [
                                  // موقع الحافلة الحالي
                                  if (busLocation != null)
                                    Marker(
                                      point: busLocation!,
                                      width: 60,
                                      height: 60,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: teal, width: 3),
                                          color: Colors.white,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.directions_bus, color: teal, size: 30),
                                      ),
                                    ),
                                  // موقع بيت الطالب
                                  if (studentHomeLocation != null)
                                    Marker(
                                      point: studentHomeLocation!,
                                      width: 45,
                                      height: 45,
                                      child: const Icon(Icons.home, color: Colors.red, size: 40),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (!isStudentOnBus)
                            Container(
                              color: Colors.black.withOpacity(0.5),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.symmetric(horizontal: 40),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.hourglass_empty, color: teal, size: 50),
                                      const SizedBox(height: 15),
                                      const Text(
                                        'بانتظار ركوب الطالب',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'سيتم تفعيل التتبع اللحظي بمجرد قيام السائق بمسح باركود الطالب',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 26,
                    child: FloatingActionButton.small(
                      heroTag: 'expandMap',
                      backgroundColor: Colors.white,
                      onPressed: _toggleMapExpanded,
                      child: const Icon(Icons.fullscreen, color: teal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 13,
        unselectedFontSize: 13,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'تتبع الباص',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'الرسوم',
          ),
        ],
      ),
    );
  }
}

class TimelineRow extends StatelessWidget {
  final String time;
  final String text;
  final bool first;
  final bool last;
  final bool active;

  const TimelineRow({
    super.key,
    required this.time,
    required this.text,
    this.first = false,
    this.last = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                if (!first)
                  Expanded(child: Container(width: 2, color: Colors.grey)),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: active ? BusTrackingScreenState.teal : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15.5),
            ),
          ),
        ],
      ),
    );
  }
}

class StepItem extends StatelessWidget {
  final IconData icon;
  final String time;
  final bool active;

  const StepItem({
    super.key,
    required this.icon,
    required this.time,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: active
              ? BusTrackingScreenState.teal
              : Colors.grey.shade200,
          child: Icon(
            icon,
            color: active ? Colors.white : BusTrackingScreenState.darkBlue,
            size: 27,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          time,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class StepConnector extends StatelessWidget {
  const StepConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 34),
        height: 3,
        color: Colors.black,
      ),
    );
  }
}

class FullScreenMap extends StatefulWidget {
  final LatLng? busLocation;
  final LatLng? studentHomeLocation;
  final List<Map<String, dynamic>> trail;
  final List<LatLng> routeToStudent;
  final LatLng defaultLocation;
  final Color teal;

  const FullScreenMap({
    super.key,
    required this.busLocation,
    required this.studentHomeLocation,
    required this.trail,
    required this.routeToStudent,
    required this.defaultLocation,
    required this.teal,
  });

  @override
  State<FullScreenMap> createState() => _FullScreenMapState();
}

class _FullScreenMapState extends State<FullScreenMap> {
  MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.busLocation ?? widget.defaultLocation,
              initialZoom: 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ayn_raqeeb',
              ),
              // عرض المسار إلى بيت الطالب
              if (widget.routeToStudent.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.routeToStudent,
                      strokeWidth: 6.0,
                      color: Colors.blue.withOpacity(0.8),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // موقع الحافلة الحالي
                  if (widget.busLocation != null)
                    Marker(
                      point: widget.busLocation!,
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: widget.teal, width: 4),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled,
                          color: Color(0xFF1B7C80),
                          size: 48,
                        ),
                      ),
                    ),
                  // موقع افتراضي إذا لم يكن هناك موقع
                  if (widget.busLocation == null)
                    Marker(
                      point: widget.defaultLocation,
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey, width: 3),
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        child: const Icon(
                          Icons.location_searching,
                          color: Colors.grey,
                          size: 48,
                        ),
                      ),
                    ),
                  // موقع بيت الطالب
                  if (widget.studentHomeLocation != null)
                    Marker(
                      point: widget.studentHomeLocation!,
                      width: 80,
                      height: 80,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 4),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // زر الإغلاق
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.pop(context),
                color: widget.teal,
              ),
            ),
          ),
          // معلومات الحافلة
          if (widget.busLocation != null)
            Positioned(
              bottom: 30,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.directions_bus,
                        color: widget.teal,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'موقع الحافلة الحالي',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.busLocation!.latitude.toStringAsFixed(6)}, ${widget.busLocation!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}