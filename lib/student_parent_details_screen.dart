import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_parent_screen.dart';

class StudentParentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final String schoolId;

  /// [schoolId] يُمرَّر عادة من شاشة المدرسة؛ إن تُرك فارغًا يُؤخذ من `student['school_id']`.
  StudentParentDetailsScreen({
    super.key,
    required this.student,
    String? schoolId,
  }) : schoolId =
            (schoolId != null && schoolId.isNotEmpty)
                ? schoolId
                : (student['school_id']?.toString() ?? '');

  @override
  Widget build(BuildContext context) {
    final sid = student['id']?.toString();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B7C80),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('تفاصيل الطالب'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${student['name']}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if ((student['student_id'] ?? student['display_id'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'معرف الطالب: ${student['student_id'] ?? student['display_id']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1B7C80),
                          ),
                        ),
                      ),
                    Text(
                      'رقم الباص: ${student['bus']}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              if (sid == null || sid.isEmpty)
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'لم يتم حفظ بيانات الطالب بعد في النظام',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('parents')
                        .where('school_id', isEqualTo: schoolId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'تعذّر تحميل بيانات ولي الأمر',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs
                              .where((d) {
                                final data = d.data();
                                final docId = (data['student_doc_id'] ?? '')
                                    .toString();
                                final legacyStudentId =
                                    (data['student_id'] ?? '').toString();
                                return docId == sid || legacyStudentId == sid;
                              })
                              .toList() ??
                          [];

                      if (docs.isNotEmpty) {
                        final parent = docs.first.data();

                        return SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.verified_user,
                                  size: 45,
                                  color: Color(0xFF1B7C80),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  parent['parent_name'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'المعرف: ${parent['parent_id']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'الجوال: ${parent['phone']}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.people_alt_outlined,
                                size: 45,
                                color: Color(0xFF1B7C80),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'لا يوجد ولي أمر مرتبط',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddParentScreen(
                                          student: student,
                                          schoolId: schoolId,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B7C80),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'إضافة ولي أمر',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
}
