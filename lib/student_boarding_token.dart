import 'dart:convert';

/// محتوى رمز QR/الباركود لصعود الطالب (يُمسحه السائق).
class StudentBoardingToken {
  static const String type = 'ayn_student_boarding_v1';

  static String encode({
    required String schoolId,
    required String studentDocId,
  }) {
    return jsonEncode({
      't': type,
      'sid': schoolId,
      'tid': studentDocId,
    });
  }

  static ({String schoolId, String studentDocId})? parse(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['t'] != type) return null;
      final sid = decoded['sid']?.toString();
      final tid = decoded['tid']?.toString();
      if (sid == null ||
          tid == null ||
          sid.isEmpty ||
          tid.isEmpty) {
        return null;
      }
      return (schoolId: sid, studentDocId: tid);
    } catch (_) {
      return null;
    }
  }
}
