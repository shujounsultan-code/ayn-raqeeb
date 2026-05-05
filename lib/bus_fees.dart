import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

// الاستيرادات التي طلبتها
import 'widgets/back_button_widget.dart';
import 'school_info_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BusFeesApp());
}

class BusFeesApp extends StatelessWidget {
  const BusFeesApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'رسوم الباص',
      theme: ThemeData(
        fontFamily: 'Tajawal',
        primaryColor: const Color(0xFF1b7c80),
        scaffoldBackgroundColor: const Color(0xFFF4F7FA),
      ),
      home: const BusFeesHome(),
    );
  }
}

// --- النماذج (Models) ---
class Student {
  final String id;
  final String name;
  final String grade;
  final String busId;
  final String status;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.busId,
    required this.status,
  });
}

// --- الشاشة الرئيسية ---
class BusFeesHome extends StatefulWidget {
  const BusFeesHome({Key? key}) : super(key: key);

  @override
  State<BusFeesHome> createState() => _BusFeesHomeState();
}

class _BusFeesHomeState extends State<BusFeesHome> {
  String filterStatus = 'all';

  // جلب البيانات بناءً على هيكلة Firestore الخاصة بك
  Stream<List<Student>> getStudentsStream() {
    return FirebaseFirestore.instance
        .collection('students') // تأكد أن اسم المجموعة 'students'
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Student(
          id: doc.id,
          name: data['name'] ?? 'بدون اسم',
          grade: data['grade'] ?? 'غير محدد',
          busId: data['bus_id'] ?? '0',
          status: data['status'] ?? 'inactive',
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1b7c80),
          elevation: 0,
          centerTitle: true,
          leading: const BackButtonWidget(), // استخدام الوجت الخاص بك
          title: const Text(
            'إدارة رسوم الباص',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        body: StreamBuilder<List<Student>>(
          stream: getStudentsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1b7c80)));
            }

            if (snapshot.hasError) {
              return Center(child: Text('حدث خطأ: ${snapshot.error}'));
            }

            final students = snapshot.data ?? [];
            
            // تصفية الطلاب بناءً على التبويب المختار
            final filteredList = filterStatus == 'all'
                ? students
                : students.where((s) => s.status == filterStatus).toList();

            return Column(
              children: [
                _buildStatsSummary(students),
                _buildFilterTabs(),
                Expanded(
                  child: _buildStudentsList(filteredList),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSummary(List<Student> list) {
    int active = list.where((s) => s.status == 'active').length;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _cardStat("الكل", list.length.toString(), Colors.blue),
          const SizedBox(width: 10),
          _cardStat("نشط", active.toString(), Colors.green),
          const SizedBox(width: 10),
          _cardStat("غير نشط", (list.length - active).toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _cardStat(String title, String val, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          children: [
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: col)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _tabBtn("الكل", "all"),
          _tabBtn("نشط", "active"),
          _tabBtn("غير نشط", "inactive"),
        ],
      ),
    );
  }

  Widget _tabBtn(String label, String code) {
    bool isSel = filterStatus == code;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => filterStatus = code),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF1b7c80) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF1b7c80)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: isSel ? Colors.white : const Color(0xFF1b7c80), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList(List<Student> list) {
    if (list.isEmpty) return const Center(child: Text("لا يوجد طلاب"));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final s = list[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF1b7c80).withOpacity(0.1),
                child: Text(s.name[0], style: const TextStyle(color: Color(0xFF1b7c80))),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("الصف: ${s.grade} | باص: ${s.busId}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: s.status == 'active' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  s.status == 'active' ? "نشط" : "غير نشط",
                  style: TextStyle(color: s.status == 'active' ? Colors.green : Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
