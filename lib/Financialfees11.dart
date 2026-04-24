import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
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

// --- نماذج البيانات (Models) ---
class Student {
  final String id;
  final String name;
  final String meta;
  final String img;
  final String status;
  final List<PaymentHistory> history;

  Student({
    required this.id,
    required this.name,
    required this.meta,
    required this.img,
    required this.status,
    required this.history,
  });
}

class PaymentHistory {
  final String label;
  final String date;
  final String price;
  final String type;

  PaymentHistory({
    required this.label,
    required this.date,
    required this.price,
    required this.type,
  });
}

// --- الشاشة الرئيسية ---
class BusFeesHome extends StatefulWidget {
  const BusFeesHome({Key? key}) : super(key: key);

  @override
  State<BusFeesHome> createState() => _BusFeesHomeState();
}

class _BusFeesHomeState extends State<BusFeesHome> {
  Map<String, Student> students = {};
  String filterStatus = 'all';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    try {
      // ملاحظة: استخدم 10.0.2.2 بدلاً من localhost لمحاكي الأندرويد
      final response = await http.get(
        Uri.parse('http://10.0.2.2/graduation-project-2-main4/graduation-project-2-main/get_payments.php'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // فك الترميز بـ UTF8 لضمان ظهور اللغة العربية
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        
        Map<String, Student> tempStudents = {};
        
        for (var row in data) {
          final id = row['student_id'].toString();
          
          if (!tempStudents.containsKey(id)) {
            tempStudents[id] = Student(
              id: id,
              name: row['student_name'] ?? 'لا يوجد اسم',
              meta: row['grade_level'] ?? 'غير محدد',
              img: 'assets/studentT.png', // المسار الصحيح للـ Assets
              status: row['status'] == 'Paid' ? 'paid' : 'unpaid',
              history: [],
            );
          }

          if (row['amount'] != null) {
            tempStudents[id]!.history.add(
              PaymentHistory(
                label: 'رسوم النقل - ${row['academic_term'] ?? 'الترم'}',
                date: row['payment_date'] ?? 'مستحق السداد',
                price: '${row['amount']} ريال',
                type: row['status'] == 'Paid' ? 'paid' : 'unpaid',
              ),
            );
          }
        }

        setState(() {
          students = tempStudents;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('خطأ في جلب البيانات: $e');
    }
  }

  int get paidCount => students.values.where((s) => s.status == 'paid').length;
  int get unpaidCount => students.values.where((s) => s.status == 'unpaid').length;

  List<Student> get filteredStudents {
    if (filterStatus == 'all') return students.values.toList();
    return students.values.where((s) => s.status == filterStatus).toList();
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
          title: const Text(
            'رسوم الباص',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF1b7c80)))
            : RefreshIndicator(
                onRefresh: fetchStudents,
                child: ListView(
                  children: [
                    _buildStatsBar(),
                    _buildTabs(),
                    _buildStudentsList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildStatChip('إجمالي الطلاب', students.length.toString()),
            const SizedBox(width: 12),
            _buildStatChip('مدفوع', paidCount.toString(), Colors.green),
            const SizedBox(width: 12),
            _buildStatChip('لم يتم الدفع', unpaidCount.toString(), Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, [Color? valueColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? const Color(0xFF1b7c80))),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          _buildTabButton('الكل', 'all'),
          const SizedBox(width: 8),
          _buildTabButton('تم الدفع', 'paid'),
          const SizedBox(width: 8),
          _buildTabButton('لم يتم الدفع', 'unpaid'),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, String status) {
    final isActive = filterStatus == status;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => filterStatus = status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1b7c80) : Colors.white,
            border: Border.all(color: isActive ? const Color(0xFF1b7c80) : const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : Colors.grey),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (filteredStudents.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 50),
        child: Center(child: Text('لا توجد بيانات متاحة')),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredStudents.length,
      itemBuilder: (context, index) => _buildStudentCard(filteredStudents[index]),
    );
  }

  Widget _buildStudentCard(Student student) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => StudentDetailScreen(student: student))),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: Colors.grey[200],
          backgroundImage: AssetImage(student.img),
          onBackgroundImageError: (_, __) {},
        ),
        title: Text(student.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        subtitle: UnconstrainedBox(
          alignment: Alignment.centerRight,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: student.status == 'paid' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              student.status == 'paid' ? 'تم الدفع' : 'لم يتم الدفع',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: student.status == 'paid' ? Colors.green : Colors.red),
            ),
          ),
        ),
        trailing: const Icon(Icons.chevron_left, color: Colors.grey),
      ),
    );
  }
}

// --- شاشة تفاصيل الدفع ---
class StudentDetailScreen extends StatelessWidget {
  final Student student;
  const StudentDetailScreen({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1b7c80),
          title: const Text('المدفوعات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildProfileCard(),
              _buildPaymentHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 32, backgroundImage: AssetImage(student.img), onBackgroundImageError: (_, __) {}),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(student.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(student.meta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[50]!, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            width: double.infinity,
            child: const Text('سجل الحركات المالية', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ...student.history.map((h) => _buildPaymentRow(h)).toList(),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(PaymentHistory h) {
    bool isPaid = h.type == 'paid';
    return ListTile(
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(isPaid ? '✓' : '!', style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.red))),
      ),
      title: Text(h.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      subtitle: Text(h.date, style: const TextStyle(fontSize: 11)),
      trailing: Text(h.price, style: TextStyle(fontWeight: FontWeight.bold, color: isPaid ? Colors.green : Colors.red)),
    );
  }
}