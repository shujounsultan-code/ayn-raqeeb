import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'driver_session.dart';
import 'driver_trip_notifier.dart';
import 'services/geocoding_service.dart';
import 'services/bus_location_service.dart';
import 'platform_utils.dart';
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
  LatLng? schoolLocation; // موقع المدرسة (ديناميكي بناءً على موقع السائق)
  StreamSubscription<Position>? _locationSubscription;
  double? busAccuracy;
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? driverData;
  final MapController _mapController = MapController();
  final TextEditingController _postalController = TextEditingController();
  LatLng? _postalPreview;
  bool _postalLoading = false;
  String? _highlightStudentId;
  String? _selectedStudentId; // الطالب المختار لعرض موقعه فقط
  
  // تتبع الطلاب الذين تم مسحهم في هذه الجلسة لتخطي موقعه والذهاب للتالي
  final Set<String> _handledStudentIds = {};

  @override
  void initState() {
    super.initState();
    driverData = DriverSession.currentDriver;
    DriverTripNotifier.lastScannedStudentId.addListener(_onStudentScanned);
    fetchData();

    // الاستماع لموقع الحافلة من الخدمة المستمرة
    _initLocationListener();
  }

  void _initLocationListener() {
    // محاولة جلب الموقع فوراً عند فتح الواجهة لضمان سرعة الاستجابة
    _getCurrentLocationImmediately();

    // جلب الموقع الحالي من الخدمة إذا كان متوفراً مسبقاً
    final currentPos = BusLocationService.currentPosition;
    if (currentPos != null && mounted) {
      setState(() {
        busLocation = LatLng(currentPos.latitude, currentPos.longitude);
        busAccuracy = currentPos.accuracy;
      });
      _moveMapToBus();
    }

    // الاشتراك في التحديثات المستمرة لضمان التحديث اللحظي
    _locationSubscription = BusLocationService.locationStream.listen((position) {
      if (!mounted) return;
      setState(() {
        busLocation = LatLng(position.latitude, position.longitude);
        busAccuracy = position.accuracy;
      });
      _moveMapToBus();
    });

    // التأكد من تشغيل الخدمة الشاملة
    if (!kIsWeb && !isWindows) {
      BusLocationService.start().then((ok) {
        if (!ok && mounted) {
          _showPermissionDeniedDialog();
        }
      });
    }
  }

  // دالة لجلب الموقع بشكل فوري ومستقل
  Future<void> _getCurrentLocationImmediately() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      if (mounted) {
        setState(() {
          busLocation = LatLng(position.latitude, position.longitude);
          busAccuracy = position.accuracy;
        });
        _moveMapToBus();
      }
    } catch (e) {
      debugPrint('Dashboard: فشل جلب الموقع الفوري، الاعتماد على الخدمة المستمرة.');
    }
  }

  // دالة آمنة لتحريك الخريطة
  void _moveMapToBus() {
    if (busLocation != null && mounted) {
      try {
        _mapController.move(busLocation!, 15);
      } catch (e) {
        // الخريطة قد لا تكون جاهزة بعد، نتجاهل الخطأ
      }
    }
  }

  String? _lastFocusedStudentId;

  void _focusOnNearestStudent() {
    if (students.isEmpty || busLocation == null) return;

    // تصفية الطلاب الذين لم يتم التعامل معهم ولهم موقع
    final pendingStudents = students.where((s) {
      return !_handledStudentIds.contains(s['id']) && s['lat'] is num && s['lng'] is num;
    }).toList();

    if (pendingStudents.isEmpty) return;

    // البحث عن الأقرب
    pendingStudents.sort((a, b) {
      final d1 = const Distance().as(
        LengthUnit.Meter,
        busLocation!,
        LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble()),
      );
      final d2 = const Distance().as(
        LengthUnit.Meter,
        busLocation!,
        LatLng((b['lat'] as num).toDouble(), (b['lng'] as num).toDouble()),
      );
      return d1.compareTo(d2);
    });

    final nearest = pendingStudents.first;
    
    // التحديث فقط إذا تغير الطالب الأقرب لضمان عدم اهتزاز الخريطة
    if (_lastFocusedStudentId != nearest['id']) {
      _lastFocusedStudentId = nearest['id'];
      _mapController.move(
        LatLng((nearest['lat'] as num).toDouble(), (nearest['lng'] as num).toDouble()),
        15,
      );
    }
  }

  void _onStudentScanned() {
    final scannedId = DriverTripNotifier.lastScannedStudentId.value;
    if (scannedId != null) {
      setState(() {
        _handledStudentIds.add(scannedId);
        _highlightStudentId = scannedId;
      });
      // بعد المسح، ننتقل تلقائياً للطالب التالي الأقرب
      _focusOnNearestStudent();
    }
    fetchData();
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('خدمة الموقع غير مفعلة'),
        content: const Text('يرجى تفعيل خدمة الموقع (GPS) من إعدادات الجهاز ليتم تحديد موقع الحافلة.'),
        actions: [
          if (!kIsWeb && !isWindows)
            TextButton(
              onPressed: () async {
                await Geolocator.openLocationSettings();
              },
              child: const Text('فتح إعدادات الموقع'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('إذن الموقع مطلوب'),
        content: const Text('يجب منح إذن الموقع لتحديد موقع الحافلة على الخريطة.'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await BusLocationService.start();
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showPermissionForeverDeniedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('إذن الموقع مرفوض نهائياً'),
        content: const Text('لقد رفضت إذن الموقع نهائياً. يرجى تفعيله من إعدادات التطبيق.'),
        actions: [
          if (!kIsWeb && !isWindows)
            TextButton(
              onPressed: () async {
                await Geolocator.openAppSettings();
              },
              child: const Text('فتح إعدادات التطبيق'),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    DriverTripNotifier.lastScannedStudentId.removeListener(_onStudentScanned);
    _locationSubscription?.cancel();
    _studentsSubscription?.cancel();
    _postalController.dispose();
    super.dispose();
  }

  StreamSubscription<QuerySnapshot>? _studentsSubscription;

  Future<void> _searchByPostal() async {
    final zip = _postalController.text.trim();
    if (zip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل الرمز البريدي أولاً')),
      );
      return;
    }
    setState(() => _postalLoading = true);
    final point = await GeocodingService.postalCodeToLatLng(zip);
    if (!mounted) return;
    setState(() {
      _postalLoading = false;
      _postalPreview = point;
    });
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يُعثر على موقع لهذا الرمز البريدي')),
      );
      return;
    }
    _mapController.move(point, 15);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم عرض الموقع على الخريطة')),
    );
  }

  Future<void> fetchData() async {
    // إلغاء الاشتراك القديم إذا وجد
    await _studentsSubscription?.cancel();
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      final busNumber = driverData != null ? driverData!['bus_number']?.toString().trim() : null;
      final schoolId = driverData != null ? driverData!['school_id']?.toString().trim() : null;
      
      // استخدام Stream للاستماع للتغييرات في Firestore
      _studentsSubscription = FirebaseFirestore.instance
          .collection('students')
          .where('school_id', isEqualTo: schoolId ?? '')
          .snapshots()
          .listen((snapshot) async {
        final List<Map<String, dynamic>> loadedStudents = [];
        final List<Map<String, dynamic>> studentsWithLocation = [];
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final sBus = (data['bus'] ?? '').toString().trim();
          debugPrint('الطالب: ${data['name']}, رقم الباص: $sBus, رقم باص السائق: $busNumber');
          if ((busNumber ?? '').isEmpty || sBus != (busNumber ?? '')) {
            debugPrint('تخطي الطالب ${data['name']} - رقم الباص غير متطابق');
            continue;
          }
          var lat = data['home_lat'];
          var lng = data['home_lng'];
          final postal = data['postal_code']?.toString().trim() ?? '';
          debugPrint('الطالب ${data['name']}: lat=$lat, lng=$lng, postal=$postal');
          if ((lat is! num || lng is! num) && postal.isNotEmpty) {
            debugPrint('محاولة تحويل الرمز البريدي: $postal');
            final point = await GeocodingService.postalCodeToLatLng(postal);
            if (point != null) {
              lat = point.latitude;
              lng = point.longitude;
              await doc.reference.update({
                'home_lat': point.latitude,
                'home_lng': point.longitude,
              });
              debugPrint('تم تحديث موقع الطالب ${data['name']}: $lat, $lng');
            } else {
              debugPrint('فشل تحويل الرمز البريدي: $postal');
            }
          }
          loadedStudents.add({
            'id': doc.id,
            'name': data['name'] ?? '',
            'lat': lat,
            'lng': lng,
            'grade': data['grade'] ?? '',
            'postal_code': postal,
          });
          if (lat is num && lng is num) {
            studentsWithLocation.add({
              'id': doc.id,
              'name': data['name'] ?? '',
              'lat': lat,
              'lng': lng,
              'grade': data['grade'] ?? '',
            });
          }
        }
        
        // استخدم موقع الحافلة اللحظي كمركز للترتيب
        final sortAnchor = busLocation ?? schoolLocation ?? const LatLng(24.7136, 46.6753);
        studentsWithLocation.sort((a, b) {
          final d1 = Distance().as(
            LengthUnit.Kilometer,
            sortAnchor,
            LatLng(
              (a['lat'] as num).toDouble(),
              (a['lng'] as num).toDouble(),
            ),
          );
          final d2 = Distance().as(
            LengthUnit.Kilometer,
            sortAnchor,
            LatLng(
              (b['lat'] as num).toDouble(),
              (b['lng'] as num).toDouble(),
            ),
          );
          return d1.compareTo(d2);
        });
        loadedStudents.sort((a, b) {
          if (a['lat'] is! num || a['lng'] is! num) return 1;
          if (b['lat'] is! num || b['lng'] is! num) return -1;
          final d1 = Distance().as(
            LengthUnit.Kilometer,
            sortAnchor,
            LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble()),
          );
          final d2 = Distance().as(
            LengthUnit.Kilometer,
            sortAnchor,
            LatLng((b['lat'] as num).toDouble(), (b['lng'] as num).toDouble()),
          );
          return d1.compareTo(d2);
        });
        
        if (!mounted) return;
        setState(() {
          students = loadedStudents;
          isLoading = false;
        });
        
        // fitBounds بعد التحميل - يركز على موقع السائق والطلاب
        if (studentsWithLocation.isNotEmpty && busLocation != null) {
          final points = [
            busLocation!,
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
        } else if (busLocation != null) {
          Future.delayed(const Duration(milliseconds: 300), () {
            _mapController.move(busLocation!, 15);
          });
        }
      }, onError: (e) {
        if (!mounted) return;
        setState(() {
          errorMessage = 'خطأ في جلب البيانات: $e';
          isLoading = false;
        });
      });
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في جلب البيانات: $e';
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // تصفية الطلاب بناءً على الاختيار
    final studentsWithLocation = students
        .where((s) => s['lat'] is num && s['lng'] is num)
        .toList();
    
    // التحقق من أن الطالب المختار لا يزال موجوداً
    if (_selectedStudentId != null && !students.any((s) => s['id'] == _selectedStudentId)) {
      _selectedStudentId = null;
    }
    
    // إذا تم اختيار طالب، عرضه فقط، وإلا عرض الطلاب الذين لم يتم التعامل معهم
    final displayStudents = _selectedStudentId != null
        ? studentsWithLocation.where((s) => s['id'] == _selectedStudentId).toList()
        : studentsWithLocation.where((s) => !_handledStudentIds.contains(s['id'])).toList();
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
                  // اختيار طالب معين لعرض موقعه
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: DropdownButtonFormField<String>(
                      value: _selectedStudentId,
                      decoration: InputDecoration(
                        labelText: 'اختر طالب لعرض موقعه',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('عرض جميع الطلاب'),
                        ),
                        ...students.map((s) => DropdownMenuItem(
                          value: s['id'],
                          child: Text(s['name'] ?? ''),
                        )),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedStudentId = val;
                        });
                      },
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
                            initialCenter: busLocation ?? schoolLocation ?? const LatLng(24.7136, 46.6753),
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(enableScrollWheel: false, enableMultiFingerGestureRace: false),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.appaynraqeeb.ayn_raqeeb',
                            ),
                            // عرض المسارات من الباص إلى جميع الطلاب المتبقين
                            if (busLocation != null && displayStudents.isNotEmpty)
                              PolylineLayer(
                                polylines: displayStudents
                                    .where((s) => s['lat'] is num && s['lng'] is num)
                                    .map((s) {
                                  return Polyline(
                                    points: [
                                      busLocation!,
                                      LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
                                    ],
                                    strokeWidth: 2.0,
                                    color: const Color(0xFF1B7C80).withOpacity(0.4),
                                    isDotted: true,
                                  );
                                }).toList(),
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
                                // Marker الحافلة (يظهر دائماً)
                                Marker(
                                  width: 50,
                                  height: 50,
                                  point: busLocation ?? schoolLocation ?? const LatLng(24.7136, 46.6753),
                                  child: GestureDetector(
                                    onTap: () {
                                      final busNumber = driverData != null ? (driverData!['bus_number']?.toString() ?? '') : '';
                                      final status = busLocation != null ? 'محدد بدقة' : 'جاري تحديد الموقع...';
                                      _showPopup(context, '🚌 باص رقم: $busNumber\nالحالة: $status');
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: busLocation != null ? const Color(0xFF1B7C80) : Colors.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                                          if (busLocation == null)
                                            const SizedBox(
                                              width: 45,
                                              height: 45,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Marker المدرسة (يظهر كمرجع)
                                if (schoolLocation != null)
                                  Marker(
                                    width: 35,
                                    height: 35,
                                    point: schoolLocation!,
                                    child: GestureDetector(
                                      onTap: () => _showPopup(context, '🏫 موقع المدرسة'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade600,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.school, color: Colors.white, size: 20),
                                      ),
                                    ),
                                  ),
                                // موقع الرمز البريدي المُدخل
                                if (_postalPreview != null)
                                  Marker(
                                    width: 30,
                                    height: 30,
                                    point: _postalPreview!,
                                    child: GestureDetector(
                                      onTap: () => _showPopup(
                                        context,
                                        '📮 موقع الرمز البريدي ${_postalController.text.trim()}',
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '📮',
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                // Markers الطالبات
                                ...displayStudents.map((s) {
                                  final isHighlight = s['id'] == _highlightStudentId;
                                  final studentLat = (s['lat'] as num).toDouble();
                                  final studentLng = (s['lng'] as num).toDouble();
                                  return Marker(
                                    width: isHighlight ? 34 : 24,
                                    height: isHighlight ? 34 : 24,
                                    point: LatLng(studentLat, studentLng),
                                    child: GestureDetector(
                                      onTap: () async {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(s['name'] ?? 'الطالب'),
                                            content: const Text('هل تريد فتح المسار إلى منزل الطالب في Google Maps؟'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(ctx).pop(),
                                                child: const Text('إغلاق'),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  Navigator.of(ctx).pop();
                                                  // موقع السائق الحالي (الحافلة)
                                                  if (busLocation == null) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('لم يتم تحديد موقع الحافلة بعد. يرجى تفعيل خدمة الموقع.')),
                                                    );
                                                    return;
                                                  }
                                                  final origin = '${busLocation!.latitude},${busLocation!.longitude}';
                                                  final dest = '$studentLat,$studentLng';
                                                  final url = Uri.parse('https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$dest&travelmode=driving');
                                                  if (await canLaunchUrl(url)) {
                                                    await launchUrl(url, mode: LaunchMode.externalApplication);
                                                  } else {
                                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعذر فتح Google Maps')));
                                                  }
                                                },
                                                child: const Text('الانتقال إلى Google Maps'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isHighlight ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                          shape: BoxShape.circle,
                                          border: isHighlight
                                              ? Border.all(color: Colors.white, width: 2)
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isHighlight ? const Color(0xFF16A34A) : const Color(0xFFD97706)).withOpacity(0.35),
                                              blurRadius: isHighlight ? 8 : 6,
                                              spreadRadius: isHighlight ? 2 : 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            isHighlight ? '✓' : '📍',
                                            style: TextStyle(
                                              fontSize: isHighlight ? 16 : 13,
                                              color: Colors.white,
                                              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
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
                        _routeStat('👧', 'المتبقي', (students.length - _handledStudentIds.length).toString()),
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
                                        padding: const EdgeInsets.only(right: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (_handledStudentIds.contains(s['id']))
                                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'الاسم : ${s['name']}',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: s['id'] == _highlightStudentId
                                                        ? const Color(0xFF16A34A)
                                                        : Colors.black,
                                                  ),
                                                  textAlign: TextAlign.right,
                                                ),
                                              ],
                                            ),
                                            if (s['lat'] is! num || s['lng'] is! num)
                                              Text(
                                                (s['postal_code']?.toString().isNotEmpty == true)
                                                    ? 'الرمز: ${s['postal_code']} — بانتظار الموقع'
                                                    : 'لا يوجد موقع أو رمز بريدي',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange.shade800,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            if (!_handledStudentIds.contains(s['id']) && s['lat'] is num)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _handledStudentIds.add(s['id']);
                                                    });
                                                    _focusOnNearestStudent();
                                                  },
                                                  style: TextButton.styleFrom(
                                                    padding: EdgeInsets.zero,
                                                    minimumSize: const Size(0, 0),
                                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  ),
                                                  child: const Text(
                                                    'تم التوصيل / الركوب',
                                                    style: TextStyle(color: Color(0xFF1B7C80), fontSize: 13, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ),
                                          ],
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

  LatLng? _routeOrigin() {
    return busLocation ?? schoolLocation;
  }

  Map<String, dynamic>? _currentRouteStudent() {
    final locStudents = students.where((s) => s['lat'] is num && s['lng'] is num).toList();
    if (locStudents.isEmpty) return null;
    if (_selectedStudentId != null) {
      return locStudents.firstWhere(
        (s) => s['id'] == _selectedStudentId,
        orElse: () => locStudents.first,
      );
    }
    final origin = _routeOrigin();
    if (origin == null) return locStudents.first;
    locStudents.sort((a, b) {
      final aDist = Distance().as(
        LengthUnit.Kilometer,
        origin,
        LatLng((a['lat'] as num).toDouble(), (a['lng'] as num).toDouble()),
      );
      final bDist = Distance().as(
        LengthUnit.Kilometer,
        origin,
        LatLng((b['lat'] as num).toDouble(), (b['lng'] as num).toDouble()),
      );
      return aDist.compareTo(bDist);
    });
    return locStudents.first;
  }

  String _estimateTime() {
    final origin = _routeOrigin();
    final current = _currentRouteStudent();
    if (origin == null || current == null) return '--';
    final target = LatLng(
      (current['lat'] as num).toDouble(),
      (current['lng'] as num).toDouble(),
    );
    final dist = Distance().as(LengthUnit.Kilometer, origin, target);
    final eta = math.max(2, (dist * 2.2).round());
    return '$eta د';
  }

  String _estimateDistance() {
    final origin = _routeOrigin();
    final current = _currentRouteStudent();
    if (origin == null || current == null) return '--';
    final target = LatLng(
      (current['lat'] as num).toDouble(),
      (current['lng'] as num).toDouble(),
    );
    final dist = Distance().as(LengthUnit.Kilometer, origin, target);
    return '${dist.toStringAsFixed(1)} كم';
  }
}

