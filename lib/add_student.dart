import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'services/geocoding_service.dart';

class AddStudentScreen extends StatefulWidget {
  final String schoolId;

  const AddStudentScreen({Key? key, required this.schoolId}) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _busIdController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  String? _selectedGrade;
  String _studentCode = '';
  bool _isLoading = false;

  final List<String> _grades = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
  ];

  @override
  void initState() {
    super.initState();
    _generateStudentCode();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _busIdController.dispose();
    _postalController.dispose();
    super.dispose();
  }

  void _generateStudentCode() {
    final random = Random();
    final code = List.generate(6, (_) => random.nextInt(10)).join();
    setState(() {
      _studentCode = code;
    });
  }

  Future<void> _addStudent() async {
    if (_nameController.text.trim().isEmpty ||
        _selectedGrade == null ||
        _busIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى تعبئة جميع الحقول')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final postal = _postalController.text.trim();
      final ref = await FirebaseFirestore.instance.collection('students').add({
        'name': _nameController.text.trim(),
        'student_code': _studentCode,
        'bus': _busIdController.text.trim(),
        'grade': _selectedGrade,
        'parent_id': '',
        'status': 'active',
        'school_id': widget.schoolId,
        if (postal.isNotEmpty) 'postal_code': postal,
        'created_at': FieldValue.serverTimestamp(),
      });
      if (postal.isNotEmpty) {
        final point = await GeocodingService.postalCodeToLatLng(postal);
        if (point != null) {
          await ref.update({
            'home_lat': point.latitude,
            'home_lng': point.longitude,
          });
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تحذير: لم يتم العثور على موقع لهذا الرمز البريدي')),
          );
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الطالب بنجاح')),
      );
      _nameController.clear();
      _busIdController.clear();
      _postalController.clear();
      _generateStudentCode();
      setState(() {
        _selectedGrade = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة طالب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم الطالب',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedGrade,
              items: _grades
                  .map((grade) => DropdownMenuItem(
                        value: grade,
                        child: Text('الصف $grade'),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedGrade = val),
              decoration: const InputDecoration(
                labelText: 'الصف',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _busIdController,
              decoration: const InputDecoration(
                labelText: 'رقم الحافلة',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _postalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'الرمز البريدي (موقع المنزل)',
                hintText: 'مثال: 21577',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'كود التحقق الفريد',
                hintText: _studentCode,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'توليد كود جديد',
                  onPressed: _generateStudentCode,
                ),
              ),
              controller: TextEditingController(text: _studentCode),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _addStudent,
                    child: const Text('حفظ'),
                  ),
          ],
        ),
      ),
    );
  }
}
