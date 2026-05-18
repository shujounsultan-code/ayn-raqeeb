import 'dart:async';
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
  Stream<Position>? _positionStream;
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

  @override
  void initState() {
    super.initState();
    driverData = DriverSession.currentDriver;
    // BusLocationService.start(); // تعطيل مؤقت لحل مشكلة الإذن
    DriverTripNotifier.lastScannedStudentId.addListener(_onStudentScanned);
    fetchData();

    // طلب إذن الموقع وتشغيل التتبع
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocationStream();
    });
  }

  Future<void> _initLocationStream() async {
    // Skip location features on web (geolocator not supported)
    if (kIsWeb) {
      debugPrint('geolocator غير مدعوم على web');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تشغيل التطبيق على Android/iOS لاستخدام الموقع')),
      );
      return;
    }

    // Skip location features on Windows desktop (geolocator not supported)
    if (isWindows) {
      debugPrint('geolocator غير مدعوم على Windows desktop');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تشغيل التطبيق على Android/iOS لاستخدام الموقع')),
      );
      return;
    }

    debugPrint('=== بدء _initLocationStream ===');
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('جاري تهيئة خدمة الموقع...')),
    );
    
    // فحص خدمة الموقع
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    debugPrint('خدمة الموقع مفعلة: $serviceEnabled');
    
    if (!serviceEnabled) {
      debugPrint('خدمة الموقع غير مفعلة');
      _showLocationServiceDialog();
      return;
    }
    
    // فحص وطلب الإذن بشكل مباشر
    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('إذن الموقع الحالي: $permission');
    
    // طلب الإذن دائماً إذا لم يكن ممنوحاً
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      debugPrint('طلب إذن الموقع...');
      permission = await Geolocator.requestPermission();
      debugPrint('إذن الموقع بعد الطلب: $permission');
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('تم رفض الإذن نهائياً');
      _showPermissionForeverDeniedDialog();
      return;
    }
    
    if (permission == LocationPermission.denied) {
      debugPrint('تم رفض الإذن');
      _showPermissionDeniedDialog();
      return;
    }
    
    debugPrint('تم منح إذن الموقع، جاري تحديد الموقع...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم منح إذن الموقع، جاري تحديد الموقع...')),
    );
    
    // الحصول على الموقع الحالي
    try {
      debugPrint('جاري الحصول على الموقع الحالي...');
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      debugPrint('تم الحصول على الموقع: ${currentPosition.latitude}, ${currentPosition.longitude}');
      
      setState(() {
        busLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
        schoolLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
        debugPrint('تم تعيين busLocation: $busLocation');
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم تحديد موقع الحافلة: ${currentPosition.latitude.toStringAsFixed(4)}, ${currentPosition.longitude.toStringAsFixed(4)}')),
      );
      
      // بدء تتبع الموقع
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      _positionStream!.listen((Position position) {
        debugPrint('موقع الباص الجديد: ${position.latitude}, ${position.longitude}');
        if (!mounted) return;
        setState(() {
          busLocation = LatLng(position.latitude, position.longitude);
        });
        // تحديث الخريطة لموقع الباص الجديد
        _mapController.move(LatLng(position.latitude, position.longitude), 15);
      });
    } catch (e) {
      debugPrint('خطأ في الحصول على الموقع: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحديد الموقع: $e')),
      );
    }
    
    debugPrint('=== انتهى _initLocationStream ===');
  }

  void _onStudentScanned() {
    _highlightStudentId = DriverTripNotifier.lastScannedStudentId.value;
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
              _initLocationStream();
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
    
    // إذا تم اختيار طالب، عرضه فقط
    final displayStudents = _selectedStudentId != null
        ? studentsWithLocation.where((s) => s['id'] == _selectedStudentId).toList()
        : studentsWithLocation;
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
                            initialCenter: busLocation ?? schoolLocation ?? const LatLng(24.7136, 46.6753), // موقع افتراضي (الرياض)
                            initialZoom: 15,
                            interactionOptions: const InteractionOptions(enableScrollWheel: false, enableMultiFingerGestureRace: false),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: const ['a', 'b', 'c'],
                              userAgentPackageName: 'com.example.ayn_raqeeb_app',
                            ),
                            // Polyline route: من الحافلة إلى كل طالب بالترتيب (متقطع)
                            if (displayStudents.isNotEmpty && busLocation != null)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [
                                      busLocation!,
                                      ...displayStudents.map(
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
                                if (schoolLocation != null)
                                  Marker(
                                    width: 32,
                                    height: 32,
                                    point: schoolLocation!,
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
                                Marker(
                                  width: 36,
                                  height: 36,
                                  point: busLocation ?? schoolLocation ?? const LatLng(24.7136, 46.6753),
                                    child: GestureDetector(
                                    onTap: () {
                                      final busNumber = driverData != null ? (driverData!['bus_number']?.toString() ?? '') : '';
                                      final locationStatus = busLocation != null ? 'محدد' : 'غير محدد';
                                      _showPopup(context, '🚌 رقم الحافلة: $busNumber\nالموقع: $locationStatus');
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: busLocation != null ? Colors.transparent : Colors.orange.withOpacity(0.3),
                                        shape: BoxShape.circle,
                                        border: busLocation != null ? null : Border.all(color: Colors.orange, width: 2),
                                      ),
                                      child: const Text('🚌', style: TextStyle(fontSize: 32)),
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
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
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

  String _estimateTime() {
    // تقدير الوقت (مطابق للـ JS: دقيقة لكل طالبة + 0.5 دقيقة/كم، يبدأ من المدرسة)
    final locStudents =
        students.where((s) => s['lat'] is num && s['lng'] is num).toList();
    if (locStudents.isEmpty) return '--';
    double totalDist = 0;
    LatLng prev = schoolLocation ?? busLocation ?? const LatLng(24.7136, 46.6753);
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
    LatLng prev = schoolLocation ?? busLocation ?? const LatLng(24.7136, 46.6753);
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

