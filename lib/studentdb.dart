import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StudentManagementApp());
}

class StudentManagementApp extends StatelessWidget {
  const StudentManagementApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نظام الطالبات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Tajawal', // تأكدي من تعريفه في pubspec.yaml
        scaffoldBackgroundColor: const Color(0xFFF0F2F8),
      ),
      home: const GradesScreen(),
    );
  }
}

// نموذج البيانات
class Student {
  final String name;
  final String bus;

  Student({required this.name, required this.bus});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['student_name'] ?? 'بدون اسم',
      bus: json['bus_number']?.toString() ?? '—',
    );
  }
}

class GradesScreen extends StatefulWidget {
  const GradesScreen({Key? key}) : super(key: key);

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final List<String> grades = ["الأول", "الثاني", "الثالث", "الرابع", "الخامس", "السادس"];
  final String baseUrl = 'http://localhost/graduation-project-2-main4/graduation-project-2-main';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الطالبات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: const Color(0xFF1B7C80),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {}, // منطق الرجوع
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قائمة الصفوف', style: TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ElevatedButton(
                  onPressed: () {}, // إضافة طالبة
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B7C80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('+ إضافة طالبة', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: grades.length,
              itemBuilder: (context, index) {
                return GradeCard(
                  name: grades[index],
                  num: (index + 1).toString(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentsListScreen(
                          gradeNum: (index + 1).toString(),
                          gradeName: grades[index],
                          baseUrl: baseUrl,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GradeCard extends StatelessWidget {
  final String name;
  final String num;
  final VoidCallback onTap;

  const GradeCard({required this.name, required this.num, required this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(color: const Color(0xFFE6FAFB), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.person, color: Color(0xFF1B7C80), size: 30),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الصف $name الابتدائي', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('عرض الطالبات', style: TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
            ),
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: const Color(0xFFE6FAFB), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF1B7C80)),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentsListScreen extends StatelessWidget {
  final String gradeNum;
  final String gradeName;
  final String baseUrl;

  const StudentsListScreen({required this.gradeNum, required this.gradeName, required this.baseUrl, Key? key}) : super(key: key);

  Future<List<Student>> fetchStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/get_students.php?grade=$gradeNum'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((s) => Student.fromJson(s)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('طالبات الصف $gradeName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B7C80),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Student>>(
        future: fetchStudents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('تعذر جلب البيانات'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد طالبات'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final student = snapshot.data![index];
              return Container(
                margin: const Offset(0, 0) & const Size(0, 10) == null ? null : const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE6FAFB),
                    child: Icon(Icons.person, color: Color(0xFF1B7C80)),
                  ),
                  title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('باص ${student.bus}', style: const TextStyle(color: Color(0xFF1B7C80))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}