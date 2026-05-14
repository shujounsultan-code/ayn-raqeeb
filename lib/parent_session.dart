import 'package:cloud_firestore/cloud_firestore.dart';

/// بيانات جلسة ولي الأمر بعد تسجيل الدخول.
class ParentSession {
  ParentSession._();

  static String? parentFirestoreDocId;
  static String? parentBusinessId;
  static Map<String, dynamic>? parentData;
  static DateTime? sessionStartedAt;

  static void setFromParentDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    parentFirestoreDocId = doc.id;
    final d = doc.data() ?? {};
    parentBusinessId = d['parent_id']?.toString().trim();
    parentData = Map<String, dynamic>.from(d);
    sessionStartedAt = DateTime.now();
  }

  static void clear() {
    parentFirestoreDocId = null;
    parentBusinessId = null;
    parentData = null;
    sessionStartedAt = null;
  }

  static String? get studentDocId =>
      parentData?['student_doc_id']?.toString().trim();

  static String? get schoolIdFromParent =>
      parentData?['school_id']?.toString().trim();

  static String? get parentName =>
      parentData?['parent_name']?.toString().trim();

  static String? get parentPhone =>
      parentData?['phone']?.toString().trim();

  /// اسم الطالب كما في سجل ولي الأمر (قد يتأخر عن تحديث الطالب).
  static String? get studentNameOnParent =>
      parentData?['student_name']?.toString().trim();

  static String? get studentBusOnParent =>
      parentData?['student_bus']?.toString().trim();
}
