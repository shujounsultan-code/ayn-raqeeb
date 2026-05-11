import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_firestore_maintenance.dart';
import 'student_parent_details_screen.dart';

/// تسميات الصف المتفق عليها في `School_fees.dart` ومجموعات واجهة الطلاب
const Map<String, String> gradeKeyToFeesLabel = {
  '1': 'أول ابتدائي',
  '2': 'ثاني ابتدائي',
  '3': 'ثالث ابتدائي',
  '4': 'رابع ابتدائي',
  '5': 'خامس ابتدائي',
  '6': 'سادس ابتدائي',
};

class StudentsScreen extends StatefulWidget {
  final String schoolId;

  const StudentsScreen({super.key, required this.schoolId});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String? _selectedGrade;

  final Map<String, String> gradeNames = {
    '1': 'الأول',
    '2': 'الثاني',
    '3': 'الثالث',
    '4': 'الرابع',
    '5': 'الخامس',
    '6': 'السادس',
  };

  int _availableSeatsFromBusData(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim()) ?? 0;
  }

  List<Map<String, dynamic>> _allBusesSorted(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final list = docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
    list.sort((a, b) {
      final na = num.tryParse(a['bus_number']?.toString() ?? '') ?? 0;
      final nb = num.tryParse(b['bus_number']?.toString() ?? '') ?? 0;
      return na.compareTo(nb);
    });
    return list;
  }

  String _bucketKeyFromStudentData(Map<String, dynamic> data) {
    final raw = data['grade_key'];
    if (raw != null && gradeNames.containsKey(raw.toString().trim())) {
      return raw.toString().trim();
    }
    final g = data['grade']?.toString().trim() ?? '';
    for (final e in gradeKeyToFeesLabel.entries) {
      if (e.value == g) return e.key;
    }
    if (gradeNames.containsKey(g)) return g;
    return 'other';
  }

  Future<void> _confirmAndRunMaintenance(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تنظيف بيانات الطلاب'),
        content: const Text(
          'سيتم:\n'
          '• حذف الطلاب الذين لا يوجد لهم ولي أمر مرتبط، أو ليس لديهم رقم باص.\n'
          '• حذف سجل ولي الأمر المرتبط عند حذف الطالب إن وُجد.\n'
          '• إرجاع مقعد الباص عند الحذف إن وُجد ربط بالباص.\n'
          '• تحديث اسم كل طالب متبٍ إلى: الاسم الأول الحالي + اسم الأب (أول كلمة من اسم ولي الأمر، أو حقل اسم الأب إن وُجد).\n\n'
          'لا يمكن التراجع. هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'تنفيذ',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري تنفيذ الصيانة...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final r = await runStudentMaintenanceForSchool(widget.schoolId);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم: حذف ${r.deletedCount} طالب، تحديث ${r.renamedCount} اسم، '
            'إرجاع ${r.busSeatsRestored} مقعد، حذف ${r.parentsDeleted} سجل ولي أمر، '
            'تخطي ${r.skippedRenameSame} (الاسم مطابق)',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشلت الصيانة: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupStudentsByGrade(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final out = <String, List<Map<String, dynamic>>>{};
    for (final k in gradeNames.keys) {
      out[k] = [];
    }
    out['other'] = [];

    for (final doc in docs) {
      final data = doc.data();
      final busVal = data['bus'];
      final bus = busVal is int
          ? busVal
          : int.tryParse(busVal?.toString() ?? '') ??
              num.tryParse(busVal?.toString() ?? '')?.toInt();

      final map = <String, dynamic>{
        'id': doc.id,
        'name': data['name'] ?? '',
        'bus': bus,
        'grade': data['grade'],
        'grade_key': data['grade_key'],
        'student_id': data['student_id'],
        'display_id': data['display_id'],
        'parent_id': data['parent_id'] ?? '',
        'school_id': data['school_id'] ?? widget.schoolId,
      };
      final bucket = _bucketKeyFromStudentData(data);
      out[bucket]?.add(map);
    }
    return out;
  }

  void _addStudentDialog() {
    final nameController = TextEditingController();
    String? selectedGradeKey;
    String? selectedBusId;
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    Future<void> addStudentFirestore(BuildContext dialogContext) async {
      final name = nameController.text.trim();
      final gradeKey = selectedGradeKey;
      final busDocumentId = selectedBusId;

      if (name.isEmpty ||
          gradeKey == null ||
          !gradeNames.containsKey(gradeKey) ||
          busDocumentId == null ||
          busDocumentId.isEmpty) {
        return;
      }

      final busRef = FirebaseFirestore.instance
          .collection('buses')
          .doc(busDocumentId);
      final studentRef =
          FirebaseFirestore.instance.collection('students').doc();
      final schoolRef = FirebaseFirestore.instance
          .collection('schools')
          .doc(widget.schoolId);

      final feesGrade = gradeKeyToFeesLabel[gradeKey];
      String? savedDisplayId;

      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snap = await transaction.get(busRef);
          if (!snap.exists) return;
          final data = snap.data();
          if (data == null) return;

          final seats =
              _availableSeatsFromBusData(data['available_seats']);
          if (seats <= 0) return;

            final busNumberStr = data['bus_number']?.toString() ?? '';
            if (busNumberStr.isEmpty) return;

          final schoolSnap = await transaction.get(schoolRef);
          var seq = 0;
          if (schoolSnap.exists && schoolSnap.data() != null) {
            seq = (schoolSnap.data()!['student_display_seq'] as num?)
                    ?.toInt() ??
                0;
          }
          final nextSeq = seq + 1;
          final displayId = 'D${nextSeq.toString().padLeft(5, '0')}';
          savedDisplayId = displayId;

          transaction.update(busRef, {'available_seats': seats - 1});
          transaction.set(studentRef, {
            'name': name,
            'grade': feesGrade ?? gradeNames[gradeKey],
            'grade_key': gradeKey,
            'bus': busNumberStr, // حفظ رقم الباص كسلسلة نصية
            'school_id': widget.schoolId,
            'student_id': displayId,
            'display_id': displayId,
            'bus_firestore_id': busDocumentId,
            'parent_id': '',
            'status': 'active',
            'created_at': FieldValue.serverTimestamp(),
          });
          transaction.set(
            schoolRef,
            {'student_display_seq': nextSeq},
            SetOptions(merge: true),
          );
        });
      } catch (_) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('تعذر حفظ الطالب أو حجز المقعد.'),
          ),
        );
        return;
      }

      final created = await studentRef.get();
      if (!created.exists || created.data() == null) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text(
              'لا توجد مقاعد متاحة في هذا الباص حالياً.',
            ),
          ),
        );
        return;
      }

      if (!dialogContext.mounted) return;
      Navigator.pop(dialogContext);
      if (!mounted) return;
      final fromDoc = (created.data()!['student_id'] ??
              created.data()!['display_id'])
          ?.toString()
          .trim();
      final sid = (savedDisplayId?.isNotEmpty == true)
          ? savedDisplayId
          : (fromDoc?.isNotEmpty == true ? fromDoc : null);
      final idMsg =
          (sid != null && sid.isNotEmpty) ? ' المعرف: $sid' : '';
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('تم حفظ الطالب بنجاح$idMsg'),
          duration: const Duration(seconds: 5),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('إضافة طالب جديد'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'اسم الطالب'),
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedGradeKey,
                      items: gradeNames.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text('الصف ${entry.value}'),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setStateDialog(() => selectedGradeKey = val),
                      decoration:
                          const InputDecoration(labelText: 'اختر الصف'),
                    ),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('buses')
                          .orderBy('bus_number')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'تعذر تحميل الباصات',
                              style: TextStyle(color: Colors.red.shade700),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final allBuses =
                            _allBusesSorted(snapshot.data!.docs);
                        int seatsOf(Map<String, dynamic> b) =>
                            _availableSeatsFromBusData(b['available_seats']);
                        final validSelectedId =
                            selectedBusId != null &&
                                    allBuses.any(
                                      (b) =>
                                          b['id'] == selectedBusId &&
                                          seatsOf(b) > 0,
                                    )
                                ? selectedBusId
                                : null;
                        if (allBuses.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'لا توجد باصات مسجلة حالياً',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          value: validSelectedId,
                          items: allBuses
                              .map((bus) {
                                final seats = seatsOf(bus);
                                final label = seats > 0
                                    ? 'باص رقم ${bus['bus_number']} — متاح: $seats'
                                    : 'باص رقم ${bus['bus_number']} — لا توجد مقاعد';
                                return DropdownMenuItem<String>(
                                  value: bus['id'] as String,
                                  enabled: seats > 0,
                                  child: Text(label),
                                );
                              })
                              .toList(),
                          onChanged: (val) =>
                              setStateDialog(() => selectedBusId = val),
                          decoration: const InputDecoration(
                            labelText: 'اختر الباص',
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B7C80),
                  ),
                  onPressed: () async {
                    await addStudentFirestore(context);
                  },
                  child: const Text('إضافة',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('school_id', isEqualTo: widget.schoolId)
            .snapshots(),
        builder: (context, snap) {
          final grouped = snap.hasData
              ? _groupStudentsByGrade(snap.data!.docs)
              : <String, List<Map<String, dynamic>>>{};

          Widget body;
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            body = const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            body = Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'تعذّر تحميل الطلاب',
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          } else {
            body = _selectedGrade == null
                ? _buildGradeList(grouped)
                : _buildStudentList(
                    grouped[_selectedGrade] ?? [],
                  );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF7F8FA),
            appBar: AppBar(
              backgroundColor: const Color(0xFF1B7C80),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              title: Text(
                _selectedGrade == null
                    ? 'الطلاب'
                    : _selectedGrade == 'other'
                        ? 'طلاب آخر صف أو غير محدد'
                        : 'طلاب الصف ${gradeNames[_selectedGrade!]}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () {
                  if (_selectedGrade != null) {
                    setState(() => _selectedGrade = null);
                  } else {
                    Navigator.pop(context);
                  }
                },
              ),
              actions: _selectedGrade == null && snap.hasData
                  ? [
                      if (!snap.hasError)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white),
                          tooltip: 'مزيد',
                          onSelected: (value) {
                            if (value == 'maintain') {
                              _confirmAndRunMaintenance(context);
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem<String>(
                              value: 'maintain',
                              child: Text('تنظيف الطلاب وتوحيد الأسماء'),
                            ),
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: TextButton.icon(
                          onPressed:
                              snap.hasError ? null : _addStudentDialog,
                          icon:
                              const Icon(Icons.add, color: Colors.white, size: 18),
                          label: const Text(
                            'إضافة طالب',
                            style: TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),
                      ),
                    ]
                  : null,
            ),
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildGradeList(
    Map<String, List<Map<String, dynamic>>> grouped,
  ) {
    final gradeKeys = gradeNames.keys.toList();
    final otherCount = grouped['other']?.length ?? 0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: gradeKeys.length + (otherCount > 0 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= gradeKeys.length) {
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const Icon(Icons.help_outline,
                  color: Color(0xFF1B7C80)),
              title: const Text('صف أو بيانات أخرى'),
              subtitle: Text('$otherCount طالب'),
              trailing:
                  const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => setState(() => _selectedGrade = 'other'),
            ),
          );
        }
        final gradeKey = gradeKeys[index];
        final count = grouped[gradeKey]?.length ?? 0;
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const Icon(Icons.class_, color: Color(0xFF1B7C80)),
            title: Text('الصف ${gradeNames[gradeKey]}'),
            subtitle: Text('$count طالب'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => setState(() => _selectedGrade = gradeKey),
          ),
        );
      },
    );
  }

  Widget _buildStudentList(List<Map<String, dynamic>> students) {
    if (students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا يوجد طلاب لهذا الصف لهذه المدرسة',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = Map<String, dynamic>.from(students[index]);

        return GestureDetector(
          onTap: () {
            final id = student['id']?.toString();
            if (id == null || id.isEmpty) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentParentDetailsScreen(
                  student: student,
                  schoolId: widget.schoolId,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/images/students.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${student['name']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      if ((student['student_id'] ??
                              student['display_id'] ??
                              '')
                          .toString()
                          .trim()
                          .isNotEmpty)
                        Text(
                          'معرف الطالب: ${student['student_id'] ?? student['display_id']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      if ((student['student_id'] ??
                              student['display_id'] ??
                              '')
                          .toString()
                          .trim()
                          .isNotEmpty)
                        const SizedBox(height: 2),
                      Text(
                        'باص ${student['bus'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B7C80),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
