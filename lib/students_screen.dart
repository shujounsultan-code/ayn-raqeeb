import 'package:flutter/material.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

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

  final Map<String, List<Map<String, dynamic>>> studentsByGrade = {
    '1': [
      {'name': 'جود العتيبي', 'bus': 12},
      {'name': 'لانا الشهراني', 'bus': 15},
      {'name': 'رهف المالكي', 'bus': 9},
    ],
    '2': [
      {'name': 'ريم الحارثي', 'bus': 12},
      {'name': 'دانة العتيبي', 'bus': 7},
      {'name': 'سارة الغامدي', 'bus': 15},
    ],
    '3': [
      {'name': 'نورة الشهري', 'bus': 9},
      {'name': 'هيا العتيبي', 'bus': 12},
      {'name': 'لمى الحربي', 'bus': 7},
    ],
    '4': [
      {'name': 'شهد الزهراني', 'bus': 15},
      {'name': 'جنى الغامدي', 'bus': 9},
      {'name': 'غلا الحارثي', 'bus': 12},
    ],
    '5': [
      {'name': 'أريام العتيبي', 'bus': 7},
      {'name': 'ليان الشهري', 'bus': 15},
      {'name': 'تالا الحربي', 'bus': 9},
    ],
    '6': [
      {'name': 'لميس الغامدي', 'bus': 12},
      {'name': 'رهف الشهري', 'bus': 7},
      {'name': 'رزان الحارثي', 'bus': 15},
    ],
  };

  void _addStudentDialog() {
    final nameController = TextEditingController();
    final gradeController = TextEditingController();
    final busController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('إضافة طالبة جديدة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'اسم الطالبة'),
              ),
              TextField(
                controller: gradeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رقم الصف (1-6)'),
              ),
              TextField(
                controller: busController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'رقم الباص'),
              ),
            ],
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
              onPressed: () {
                final name = nameController.text.trim();
                final grade = gradeController.text.trim();
                final bus = int.tryParse(busController.text.trim());

                if (name.isEmpty || !studentsByGrade.containsKey(grade) || bus == null) {
                  return;
                }

                setState(() {
                  studentsByGrade[grade]!.add({'name': name, 'bus': bus});
                });
                Navigator.pop(ctx);
              },
              child: const Text('إضافة', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B7C80),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _selectedGrade == null
                ? 'الطالبات'
                : 'طالبات الصف ${gradeNames[_selectedGrade!]}',
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
          actions: _selectedGrade == null
              ? [
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: TextButton.icon(
                      onPressed: _addStudentDialog,
                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                      label: const Text(
                        'إضافة طالبة',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ]
              : null,
        ),
        body: _selectedGrade == null ? _buildGradeList() : _buildStudentList(),
      ),
    );
  }

  Widget _buildGradeList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: gradeNames.length,
      itemBuilder: (context, index) {
        final gradeKey = (index + 1).toString();
        final gradeName = gradeNames[gradeKey]!;
        final count = studentsByGrade[gradeKey]?.length ?? 0;

        return GestureDetector(
          onTap: () => setState(() => _selectedGrade = gradeKey),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E2E2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                        'الصف $gradeName الابتدائي',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count طالبات',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1B7C80),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentList() {
    final students = studentsByGrade[_selectedGrade!] ?? [];

    if (students.isEmpty) {
      return const Center(
        child: Text(
          'لا توجد طالبات.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      student['name'],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'باص ${student['bus']}',
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
        );
      },
    );
  }
}
