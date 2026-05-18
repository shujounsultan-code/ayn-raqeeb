import 'package:cloud_firestore/cloud_firestore.dart';
import '../parent_session.dart';

/// يحدد قائمة الطلاب المرتبطين بولي الأمر: أولاً بـ `parent_id` على مستند الطالب،
/// وإن لم يوجد يُستخدم `student_doc_id` من سجل ولي الأمر.
Stream<List<DocumentSnapshot<Map<String, dynamic>>>> parentLinkedStudentsStream() {
  final pid = ParentSession.parentBusinessId;
  final fallbackSid = ParentSession.studentDocId;

  if (pid != null && pid.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection('students')
        .where('parent_id', isEqualTo: pid)
        .snapshots()
        .asyncMap((snap) async {
      if (snap.docs.isNotEmpty) {
        return List<DocumentSnapshot<Map<String, dynamic>>>.from(snap.docs);
      }

      final parentQuery = await FirebaseFirestore.instance
          .collection('parents')
          .where('parent_id', isEqualTo: pid)
          .limit(1)
          .get();
      if (parentQuery.docs.isNotEmpty) {
        final parentDocId = parentQuery.docs.first.id;
        final alternateSnap = await FirebaseFirestore.instance
            .collection('students')
            .where('parent_id', isEqualTo: parentDocId)
            .get();
        if (alternateSnap.docs.isNotEmpty) {
          return List<DocumentSnapshot<Map<String, dynamic>>>.from(
              alternateSnap.docs);
        }
      }

      if (fallbackSid != null && fallbackSid.isNotEmpty) {
        final d = await FirebaseFirestore.instance
            .collection('students')
            .doc(fallbackSid)
            .get();
        if (d.exists) return [d];
      }
      return <DocumentSnapshot<Map<String, dynamic>>>[];
    });
  }

  if (fallbackSid != null && fallbackSid.isNotEmpty) {
    return FirebaseFirestore.instance
        .collection('students')
        .doc(fallbackSid)
        .snapshots()
        .map((d) => d.exists ? <DocumentSnapshot<Map<String, dynamic>>>[d] : []);
  }

  return Stream.value([]);
}

Map<String, dynamic> studentDocAsMap(DocumentSnapshot<Map<String, dynamic>> d) {
  return {
    'id': d.id,
    ...?d.data(),
  };
}
