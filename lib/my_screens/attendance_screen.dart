import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../parent_session.dart';
import 'parent_student_scope.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color mainColor = Color(0xFF1B7C80);

  String? _selectedStudentDocId;
  String _status = '';

  Future<void> _registerStatus(String newStatus, String studentDocId) async {
    final pid = ParentSession.parentBusinessId;
    if (studentDocId.isEmpty) {
      _showMessage('اختر الطالب أولاً');
      return;
    }

    setState(() => _status = newStatus);

    try {
      await FirebaseFirestore.instance.collection('parent_attendance').add({
        'parent_id': pid,
        'student_doc_id': studentDocId,
        'status': newStatus,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      _showMessage(
        newStatus == 'حاضر'
            ? 'تم تسجيل حضور الطالب'
            : 'تم تسجيل غياب الطالب',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('تعذّر الحفظ: $e');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.right),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _effectiveStudentDocId(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return '';
    final sel = _selectedStudentDocId;
    if (sel != null && docs.any((d) => d.id == sel)) return sel;
    return docs.first.id;
  }

  DocumentSnapshot<Map<String, dynamic>>? _docById(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
    String id,
  ) {
    for (final d in docs) {
      if (d.id == id) return d;
    }
    return docs.isEmpty ? null : docs.first;
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = ParentSession.schoolIdFromParent ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    InkWell(
                      onTap: () =>
                          _showMessage('التنبيهات تظهر تلقائياً عند وجودها'),
                      child: const Icon(Icons.notifications_none, size: 28),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _showMessage('لا توجد رسائل حالياً'),
                      child: const Icon(Icons.chat_bubble_outline, size: 26),
                    ),
                    const Spacer(),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/logobg.png',
                          width: 90,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.school,
                            size: 40,
                            color: mainColor,
                          ),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: const Text(
                            'عين رقيب',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: mainColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      ParentSession.parentName ?? 'ولي الأمر',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if ((ParentSession.parentPhone ?? '').isNotEmpty)
                      Text(
                        'جوال: ${ParentSession.parentPhone}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                  ],
                ),
              ),
              if (schoolId.isNotEmpty)
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('schools')
                      .doc(schoolId)
                      .snapshots(),
                  builder: (context, sch) {
                    final name =
                        sch.data?.data()?['school_name']?.toString() ??
                            'المدرسة';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF6F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'المدرسة: $name',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: mainColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                  stream: parentLinkedStudentsStream(),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'تعذّر تحميل بيانات الطلاب: ${snap.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final docs = snap.data ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'لا يوجد طالب مرتبط بحسابك في النظام. راجع المدرسة لربط الطالب أو تحديث حقل parent_id.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    }

                    final effId = _effectiveStudentDocId(docs);
                    final selected = _docById(docs, effId);

                    if (selected == null || !selected.exists) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final m = studentDocAsMap(selected);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (docs.length > 1)
                            DropdownButtonFormField<String>(
                              value: effId,
                              decoration: const InputDecoration(
                                labelText: 'الطالب',
                                border: OutlineInputBorder(),
                              ),
                              items: docs.map((d) {
                                final n =
                                    d.data()?['name']?.toString() ?? d.id;
                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text(n, textAlign: TextAlign.right),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedStudentDocId = v);
                                }
                              },
                            )
                          else
                            const SizedBox.shrink(),

                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.asset(
                                      'assets/images/student.png',
                                      width: 140,
                                      height: 68,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.person, size: 64),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 22),

                                _infoLine(
                                  'الاسم',
                                  m['name']?.toString() ?? '—',
                                ),
                                _infoLine(
                                  'الصف',
                                  m['grade']?.toString() ?? '—',
                                ),
                                _infoLine(
                                  'رقم الباص',
                                  m['bus']?.toString() ?? '—',
                                ),
                                if ((m['student_id'] ??
                                        m['display_id'] ??
                                        '')
                                    .toString()
                                    .isNotEmpty)
                                  _infoLine(
                                    'معرف الطالب',
                                    m['student_id']?.toString() ??
                                        m['display_id']?.toString() ??
                                        '',
                                    valueColor: mainColor,
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          Center(
                            child: Text(
                              'يرجى تحديد حالة حضور الطالب لهذا اليوم',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            textDirection: TextDirection.ltr,
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => _registerStatus('غائب', effId),
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: _status == 'غائب'
                                          ? Colors.red.shade700
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'غائب',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _registerStatus('حاضر', effId),
                                  child: Container(
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: _status == 'حاضر'
                                          ? Colors.green.shade700
                                          : Colors.green,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'حاضر',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        textDirection: TextDirection.rtl,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              '$label:',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LabelText extends StatelessWidget {
  final String text;

  const LabelText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(':'),
      ],
    );
  }
}