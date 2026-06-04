import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../platform_utils.dart';

import '../driver_session.dart';

class BusLocationService {
  static StreamSubscription<Position>? _positionSub;
  static String? _docId;
  static final List<Map<String, dynamic>> _trail = [];
  static const int _maxTrailPoints = 120;

  // إضافة StreamController لبث تحديثات الموقع للواجهات الأخرى
  static final StreamController<Position> _locationStreamController = StreamController<Position>.broadcast();
  static Stream<Position> get locationStream => _locationStreamController.stream;
  static Position? _currentPosition;
  static Position? get currentPosition => _currentPosition;

  static String? _resolveDocId() {
    final driver = DriverSession.currentDriver;
    if (driver == null) return null;
    final schoolId = driver['school_id']?.toString().trim() ?? '';
    final busNumber = driver['bus_number']?.toString().trim() ?? '';
    if (schoolId.isEmpty || busNumber.isEmpty) return null;
    return '${schoolId}_$busNumber';
  }

  static Future<bool> ensurePermission() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return false;
    }
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> start() async {
    if (kIsWeb) {
      return false;
    }

    final id = _resolveDocId();
    if (id == null) return false;
    if (_positionSub != null && _docId == id) return true;

    await stop();
    final ok = await ensurePermission();
    if (!ok) return false;

    _docId = id;
    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5,
    );

    try {
      // محاولة الحصول على آخر موقع معروف أولاً لسرعة الاستجابة
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        await _onPosition(lastKnown);
      }

      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      await _onPosition(currentPosition);
    } catch (e) {
      debugPrint('BusLocationService: فشل الحصول على الموقع الفوري: $e');
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: kIsWeb || isWindows 
        ? const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5)
        : defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
              forceLocationManager: true,
              intervalDuration: const Duration(seconds: 5),
            )
          : AppleSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
              pauseLocationUpdatesAutomatically: false,
              showBackgroundLocationIndicator: true,
            ),
    ).listen(_onPosition, onError: (e) {
      debugPrint('BusLocationService: خطأ في تدفق الموقع: $e');
    });
    return true;
  }

  static Future<void> _onPosition(Position pos) async {
    _currentPosition = pos;
    _locationStreamController.add(pos);
    
    final id = _docId;
    if (id == null) return;

    _trail.add({
      'lat': pos.latitude,
      'lng': pos.longitude,
      't': DateTime.now().millisecondsSinceEpoch,
    });
    if (_trail.length > _maxTrailPoints) {
      _trail.removeRange(0, _trail.length - _maxTrailPoints);
    }

    final driver = DriverSession.currentDriver;

    // إرسال الإحداثيات إلى السيرفر المحلي (FastAPI)
    _sendToLocalBackend(pos.latitude, pos.longitude);

    await FirebaseFirestore.instance.collection('bus_locations').doc(id).set({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'accuracy': pos.accuracy,
      'school_id': driver?['school_id'],
      'bus_number': driver?['bus_number'],
      'trail': List<Map<String, dynamic>>.from(_trail),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _sendToLocalBackend(double lat, double lng) async {
    try {
      final url = Uri.parse('http://127.0.0.1:8000/documents/manual-qa');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': lat,
          'longitude': lng,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('BusLocationService: تم إرسال الموقع بنجاح للسيرفر المحلي');
      } else {
        debugPrint('BusLocationService: فشل إرسال الموقع للسيرفر المحلي: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('BusLocationService: خطأ في الاتصال بالسيرفر المحلي: $e');
    }
  }

  static Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _docId = null;
    _trail.clear();
  }
}
