import 'package:cloud_firestore/cloud_firestore.dart';

/// نتيجة تشغيل صيانة طلاب المدرسة (حذف غير المكتملين + توحيد الأسماء).
class StudentMaintenanceResult {
  StudentMaintenanceResult({
    required this.deletedCount,
    required this.renamedCount,
    required this.busSeatsRestored,
    required this.parentsDeleted,
    required this.skippedRenameSame,
  });

  final int deletedCount;
  final int renamedCount;
  final int busSeatsRestored;
  final int parentsDeleted;
  final int skippedRenameSame;
}

String _firstWord(String raw) {
  for (final part in raw.trim().split(RegExp(r'\s+'))) {
    if (part.isNotEmpty) return part;
  }
  return '';
}

String _fatherFirstName(Map<String, dynamic> parentData) {
  final explicit = parentData['father_name'] ??
      parentData['fatherName'] ??
      parentData['اسم_الاب'];
  if (explicit != null && explicit.toString().trim().isNotEmpty) {
    return _firstWord(explicit.toString());
  }
  return _firstWord((parentData['parent_name'] ?? '').toString());
}

bool _studentHasBus(Map<String, dynamic> data) {
  final b = data['bus'];
  if (b == null) return false;
  if (b is int && b <= 0) return false;
  final n = int.tryParse(b.toString()) ?? (b is num ? b.toInt() : null);
  if (n == null || n <= 0) return false;
  return true;
}

/// يحذف طلاب المدرسة الذين ليس لديهم ولي أمر مرتبط أو ليس لديهم رقم باص صالح،
/// ويعيد مقعد الباص عند الحذف إن وُجد [bus_firestore_id].
/// للباقين: يحدّث [name] إلى «الاسم الأول للطالب + اسم الأب» من بيانات ولي الأمر
/// (أول كلمة من [parent_name] أو من [father_name] إن وُجدت)، ويحدّث [student_name] في مستند ولي الأمر.
Future<StudentMaintenanceResult> runStudentMaintenanceForSchool(
  String schoolId,
) async {
  final fs = FirebaseFirestore.instance;
  final school = schoolId.trim();
  if (school.isEmpty) {
    return StudentMaintenanceResult(
      deletedCount: 0,
      renamedCount: 0,
      busSeatsRestored: 0,
      parentsDeleted: 0,
      skippedRenameSame: 0,
    );
  }

  final studentsSnap = await fs
      .collection('students')
      .where('school_id', isEqualTo: school)
      .get();

  final parentsSnap = await fs
      .collection('parents')
      .where('school_id', isEqualTo: school)
      .get();

  final parentsByDocId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
    for (final p in parentsSnap.docs) p.id: p,
  };

  final parentsByStudentDocId =
      <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
  for (final p in parentsSnap.docs) {
    final sd = (p.data()['student_doc_id'] ?? '').toString().trim();
    if (sd.isNotEmpty) {
      parentsByStudentDocId[sd] = p;
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? parentForStudent(
    String studentDocId,
    Map<String, dynamic> studentData,
  ) {
    final pid = (studentData['parent_id'] ?? '').toString().trim();
    if (pid.isNotEmpty) {
      final byId = parentsByDocId[pid];
      if (byId != null) return byId;
    }
    return parentsByStudentDocId[studentDocId];
  }

  var deletedCount = 0;
  var renamedCount = 0;
  var busSeatsRestored = 0;
  var parentsDeleted = 0;
  var skippedRenameSame = 0;

  final toDelete = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final toRename =
      <({QueryDocumentSnapshot<Map<String, dynamic>> doc, String newName})>[];

  for (final doc in studentsSnap.docs) {
    final data = doc.data();
    final parent = parentForStudent(doc.id, data);
    final hasParent = parent != null;
    final hasBus = _studentHasBus(data);

    if (!hasParent || !hasBus) {
      toDelete.add(doc);
      continue;
    }

    final pData = parent.data();
    final childFirst = _firstWord((data['name'] ?? '').toString());
    final fatherFirst = _fatherFirstName(pData);
    String newName;
    if (childFirst.isEmpty && fatherFirst.isEmpty) {
      continue;
    } else if (fatherFirst.isEmpty) {
      newName = childFirst;
    } else if (childFirst.isEmpty) {
      newName = fatherFirst;
    } else {
      newName = '$childFirst $fatherFirst';
    }

    final oldName = (data['name'] ?? '').toString().trim();
    if (newName == oldName) {
      skippedRenameSame++;
      continue;
    }
    toRename.add((doc: doc, newName: newName));
  }

  Future<void> flushBatch(WriteBatch batch, int opCount) async {
    if (opCount > 0) {
      await batch.commit();
    }
  }

  var batch = fs.batch();
  var ops = 0;

  Future<void> commitBatchIfLarge() async {
    if (ops >= 400) {
      await flushBatch(batch, ops);
      batch = fs.batch();
      ops = 0;
    }
  }

  for (final doc in toDelete) {
    final data = doc.data();
    final parent = parentForStudent(doc.id, data);

    final busFsId = (data['bus_firestore_id'] ?? '').toString().trim();
    if (busFsId.isNotEmpty) {
      final busRef = fs.collection('buses').doc(busFsId);
      batch.update(busRef, {'available_seats': FieldValue.increment(1)});
      ops++;
      busSeatsRestored++;
      await commitBatchIfLarge();
    }

    if (parent != null) {
      batch.delete(parent.reference);
      ops++;
      parentsDeleted++;
      await commitBatchIfLarge();
    }

    batch.delete(doc.reference);
    ops++;
    deletedCount++;
    await commitBatchIfLarge();
  }

  await flushBatch(batch, ops);
  batch = fs.batch();
  ops = 0;

  for (final item in toRename) {
    final doc = item.doc;
    final newName = item.newName;
    final parent = parentForStudent(doc.id, doc.data());
    batch.update(doc.reference, {'name': newName});
    ops++;
    renamedCount++;
    if (parent != null) {
      batch.update(parent.reference, {'student_name': newName});
      ops++;
    }
    await commitBatchIfLarge();
  }

  await flushBatch(batch, ops);

  return StudentMaintenanceResult(
    deletedCount: deletedCount,
    renamedCount: renamedCount,
    busSeatsRestored: busSeatsRestored,
    parentsDeleted: parentsDeleted,
    skippedRenameSame: skippedRenameSame,
  );
}
