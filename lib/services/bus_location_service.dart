import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../platform_utils.dart';

import '../driver_session.dart';

/// يرسل موقع الحافلة ومسار الرحلة إلى `bus_locations` ليظهر عند السائق وولي الأمر.
class BusLocationService {
  static StreamSubscription<Position>? _positionSub;
  static String? _docId;
  static final List<Map<String, dynamic>> _trail = [];
  static const int _maxTrailPoints = 120;

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
    // Skip location features on web and Windows desktop (geolocator not supported)
    if (kIsWeb || isWindows) {
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
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      await _onPosition(currentPosition);
    } catch (_) {
      // ignore: avoid_print
      print('BusLocationService: failed to get current position immediately.');
    }

    _positionSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen(_onPosition, onError: (_) {});
    return true;
  }

  static Future<void> _onPosition(Position pos) async {
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

  static Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _docId = null;
    _trail.clear();
  }
}
