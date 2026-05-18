import 'package:flutter/foundation.dart';

class DriverTripNotifier {
  static final ValueNotifier<String?> lastScannedStudentId = ValueNotifier<String?>(null);

  static void onStudentScanned(String? studentId) {
    lastScannedStudentId.value = studentId;
  }
}
