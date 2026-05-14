import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_parent_screen.dart';
import 'widgets/student_boarding_qr_card.dart';

class StudentParentDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> student;
  final String schoolId;

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
    final displayCode = (student['student_id'] ?? student['display_id'] ?? '')
        .toString()
        .trim();

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
        body: sid == null || sid.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'لم يتم حفظ بيانات الطالب بعد في النظام',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: _headerCard(student, displayCode),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: StudentBoardingQrCard(
                        schoolId: schoolId,
                        studentDocId: sid,
                        studentDisplayCode:
                            displayCode.isNotEmpty ? displayCode : null,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    sliver: SliverToBoxAdapter(
                      child: _ParentSection(
                        schoolId: schoolId,
                        studentDocId: sid,
                        student: student,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _headerCard(Map<String, dynamic> student, String displayCode) {
    return Container(
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
          if (displayCode.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'معرف الطالب: $displayCode',
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
    );
  }
}

class _ParentSection extends StatelessWidget {
  const _ParentSection({
    required this.schoolId,
    required this.studentDocId,
    required this.student,
  });

  final String schoolId;
  final String studentDocId;
  final Map<String, dynamic> student;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('parents')
          .where('school_id', isEqualTo: schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'تعذّر تحميل بيانات ولي الأمر',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final docs = snapshot.data?.docs.where((d) {
              final data = d.data();
              final docId = (data['student_doc_id'] ?? '').toString();
              final legacyStudentId = (data['student_id'] ?? '').toString();
              return docId == studentDocId || legacyStudentId == studentDocId;
            }).toList() ??
            [];

        if (docs.isNotEmpty) {
          final parent = docs.first.data();
          return Container(
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
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          );
        }

        return Container(
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
        );
      },
    );
  }
}
