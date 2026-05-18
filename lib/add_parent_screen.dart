import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddParentScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  final String schoolId;

  const AddParentScreen({
    super.key,
    required this.student,
    required this.schoolId,
  });

  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _parentNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _parentNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniqueParentId() async {
    final fs = FirebaseFirestore.instance;
    final rand = Random();

    for (var i = 0; i < 10; i++) {
      final digits = List.generate(6, (_) => rand.nextInt(10)).join();
      final candidate = 'P$digits';
      final snap = await fs
          .collection('parents')
          .where('parent_id', isEqualTo: candidate)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) return candidate;
    }

    final fallback = (DateTime.now().millisecondsSinceEpoch % 1000000)
        .toString()
        .padLeft(6, '0');
    return 'P$fallback';
  }

  Future<void> _saveParent() async {
    final parentName = _parentNameController.text.trim();
    final phone = _phoneController.text.trim();

    if (parentName.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتبي اسم ولي الأمر ورقم الجوال')),
      );
      return;
    }

    final studentDocId = widget.student['id']?.toString();
    if (studentDocId == null || studentDocId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر الربط: الطالب غير مسجل في النظام (لا يوجد معرف مستند)',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fs = FirebaseFirestore.instance;
      final schoolId = widget.schoolId.trim();

      final parentQuery = await fs
          .collection('parents')
          .where('school_id', isEqualTo: schoolId)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      final studentRef = fs.collection('students').doc(studentDocId);
      final batch = fs.batch();

      final studentCode = (widget.student['student_id'] ??
              widget.student['display_id'] ??
              '')
          .toString()
          .trim();

      final bool parentAlreadyExists = parentQuery.docs.isNotEmpty;
      late final DocumentReference<Map<String, dynamic>> parentRef;
      String displayParentId = '';
      String password = '';

      if (parentAlreadyExists) {
        final doc = parentQuery.docs.first;
        parentRef = doc.reference;
        final data = doc.data();
        displayParentId = (data['parent_id'] ?? '').toString().trim();
        password = (data['password'] ?? '').toString();
      } else {
        parentRef = fs.collection('parents').doc();
        displayParentId = await _generateUniqueParentId();
        password = _generatePassword();
      }

      final parentData = <String, dynamic>{
        'parent_id': displayParentId,
        'parent_name': parentName,
        'phone': phone,
        'school_id': schoolId,
        'student_doc_id': studentDocId,
        'student_id': studentCode,
        'student_name': widget.student['name'],
        'student_bus': widget.student['bus'],
        'status': 'active',
      };

      if (!parentAlreadyExists) {
        parentData['password'] = password;
        parentData['created_at'] = FieldValue.serverTimestamp();
      } else if (password.isEmpty) {
        password = _generatePassword();
        parentData['password'] = password;
      }

      batch.set(parentRef, parentData, SetOptions(merge: true));
      batch.update(studentRef, {'parent_id': displayParentId});
      await batch.commit();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parentAlreadyExists
                ? 'تم ربط الطالب بولي الأمر الموجود'
                : 'تم إضافة ولي الأمر وربط الطالب به. المعرف: $displayParentId كلمة المرور: $password',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF1B7C80),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studentName = widget.student['name'];
    final studentBus = widget.student['bus'];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B7C80),
          foregroundColor: Colors.white,
          centerTitle: true,
          title: const Text('إضافة ولي أمر'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E2E2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الطالب: $studentName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الباص: $studentBus',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1B7C80),
                      ),
                    ),
                  ],
                ),
              ),
              _field(
                controller: _parentNameController,
                label: 'اسم ولي الأمر',
              ),
              _field(
                controller: _phoneController,
                label: 'رقم الجوال',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveParent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B7C80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ ولي الأمر',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
