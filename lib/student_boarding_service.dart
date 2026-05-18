import 'package:cloud_firestore/cloud_firestore.dart';
import 'driver_session.dart';
import 'driver_trip_notifier.dart';
import 'services/geocoding_service.dart';
import 'student_boarding_token.dart';

/// يتحقق من رمز المسح، يطابق المدرسة والباص مع السائق، ويسجّل الحدث ويُنشئ تنبيهاً لولي الأمر.
Future<String?> recordStudentBoardingFromScan(String raw) async {
  final parsed = StudentBoardingToken.parse(raw);
  if (parsed == null) {
    return 'رمز غير صالح. استخدم رمز الطالب من تطبيق المدرسة.';
  }

  final driver = DriverSession.currentDriver;
  if (driver == null) {
    return 'يجب تسجيل الدخول كسائق أولاً.';
  }

  final schoolIdDriver = driver['school_id']?.toString().trim() ?? '';
  final busNumDriver = driver['bus_number']?.toString().trim() ?? '';
  if (schoolIdDriver.isEmpty || busNumDriver.isEmpty) {
    return 'بيانات السائق ناقصة (مدرسة أو باص).';
  }

  final studentRef = FirebaseFirestore.instance
      .collection('students')
      .doc(parsed.studentDocId);
  final st = await studentRef.get();
  if (!st.exists || st.data() == null) {
    return 'الطالب غير موجود في النظام.';
  }
  final data = st.data()!;

  final schoolStudent = data['school_id']?.toString().trim() ?? '';
  if (schoolStudent != schoolIdDriver) {
    return 'هذا الطالب ليس من مدرستك.';
  }

  final studentBus = data['bus']?.toString().trim() ?? '';
  if (studentBus != busNumDriver) {
    return 'هذا الطالب غير مسجّل على باصك (باص $studentBus).';
  }

  final recent = await FirebaseFirestore.instance
      .collection('board_events')
      .where('student_doc_id', isEqualTo: parsed.studentDocId)
      .limit(8)
      .get();

  final now = DateTime.now();
  for (final d in recent.docs) {
    final c = d.data()['created_at'];
    if (c is Timestamp) {
      if (now.difference(c.toDate()) < const Duration(seconds: 45)) {
        return 'تم تسجيل صعود هذا الطالب للتو.';
      }
    }
  }

  var parentBusinessId = data['parent_id']?.toString().trim() ?? '';
  if (parentBusinessId.isNotEmpty) {
    final parentDoc = await FirebaseFirestore.instance
        .collection('parents')
        .doc(parentBusinessId)
        .get();
    if (parentDoc.exists) {
      parentBusinessId =
          parentDoc.data()?['parent_id']?.toString().trim() ?? parentBusinessId;
    }
  }

  if (parentBusinessId.isEmpty) {
    final pq = await FirebaseFirestore.instance
        .collection('parents')
        .where('student_doc_id', isEqualTo: parsed.studentDocId)
        .limit(1)
        .get();
    if (pq.docs.isNotEmpty) {
      parentBusinessId =
          pq.docs.first.data()['parent_id']?.toString().trim() ?? '';
    }
  }

  final nameRaw = data['name']?.toString().trim() ?? '';
  final studentName = nameRaw.isNotEmpty ? nameRaw : 'الطالب';

  final fs = FirebaseFirestore.instance;
  final batch = fs.batch();
  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final be = fs.collection('board_events').doc();
  final busLocationDocId = '${schoolIdDriver}_$busNumDriver';
  batch.set(be, {
    'school_id': schoolIdDriver,
    'student_doc_id': parsed.studentDocId,
    'student_name': studentName,
    'bus_number': busNumDriver,
    'bus_location_doc_id': busLocationDocId,
    'parent_id': parentBusinessId,
    'driver_id': driver['driver_id'],
    'created_at': FieldValue.serverTimestamp(),
    'created_at_ms': nowMs,
  });

  if (parentBusinessId.isNotEmpty) {
    final pn = fs.collection('parent_notifications').doc();
    batch.set(pn, {
      'parent_id': parentBusinessId,
      'title': 'بدء تتبع رحلة الطالب',
      'body': 'تم مسح باركود $studentName وبدأ تتبع الحافلة رقم $busNumDriver.',
      'type': 'student_boarded',
      'read': false,
      'student_doc_id': parsed.studentDocId,
      'bus_number': busNumDriver,
      'school_id': schoolIdDriver,
      'bus_location_doc_id': busLocationDocId,
      'driver_id': driver['driver_id'],
      'created_at': FieldValue.serverTimestamp(),
      'created_at_ms': nowMs,
    });
  }

  await batch.commit();

  // ضمان ظهور موقع الطالب على خريطة السائق (من الإحداثيات أو الرمز البريدي)
  final hasCoords =
      data['home_lat'] is num && data['home_lng'] is num;
  if (!hasCoords) {
    final postal = data['postal_code']?.toString().trim() ?? '';
    if (postal.isNotEmpty) {
      final point = await GeocodingService.postalCodeToLatLng(postal);
      if (point != null) {
        await studentRef.update({
          'home_lat': point.latitude,
          'home_lng': point.longitude,
        });
      }
    }
  }

  DriverTripNotifier.onStudentScanned(parsed.studentDocId);

  if (parentBusinessId.isEmpty) {
    return 'ok_no_parent';
  }
  return null;
}
