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
      final response = await http.get(
        Uri.parse('http://localhost/graduation-project-2-main4/graduation-project-2-main/get_payments.php'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => http.Response('timeout', 408),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        setState(() {
          students.clear();
          
          for (var row in data) {
            final id = row['student_id'].toString();
            
            if (!students.containsKey(id)) {
              students[id] = Student(
                id: id,
                name: row['student_name'] ?? 'لا يوجد اسم',
                meta: row['grade_level'] ?? 'غير محدد',
                img: 'studentT.png',
                status: row['status'] == 'Paid' ? 'paid' : 'unpaid',
                history: [],
              );
            }

            if (row['amount'] != null) {
              students[id]!.history.add(
                PaymentHistory(
                  label: 'رسوم النقل - ${row['academic_term'] ?? 'الترم'}',
                  date: row['payment_date'] ?? 'مستحق السداد',
                  price: '${row['amount']} ريال',
                  type: row['status'] == 'Paid' ? 'paid' : 'unpaid',
                ),
              );
            }
          }
          
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('خطأ في جلب البيانات: $e');
    }
  }

  int get paidCount => students.values.where((s) => s.status == 'paid').length;
  int get unpaidCount => students.values.where((s) => s.status == 'unpaid').length;

  List<Student> get filteredStudents {
    if (filterStatus == 'all') {
      return students.values.toList();
    }
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1b7c80),
                ),
              )
            : RefreshIndicator(
                onRefresh: fetchStudents,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // إحصائيات
                      _buildStatsBar(),
                      // التبويبات
                      _buildTabs(),
                      // قائمة الطلاب
                      _buildStudentsList(),
                    ],
                  ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1b7c80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
      child: GestureDetector(
        onTap: () {
          setState(() {
            filterStatus = status;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF1b7c80) : Colors.white,
            border: Border.all(
              color: isActive
                  ? const Color(0xFF1b7c80)
                  : const Color(0xFFE5E7EB),
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF1b7c80).withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsList() {
    if (filteredStudents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد بيانات',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Column(
        children: filteredStudents.map((student) {
          return _buildStudentCard(student);
        }).toList(),
      ),
    );
  }

  Widget _buildStudentCard(Student student) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(student: student),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[300],
              backgroundImage: AssetImage('assets/studentT.png'),
              onBackgroundImageError: (exception, stackTrace) {},
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: student.status == 'paid'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      student.status == 'paid' ? 'تم الدفع' : 'لم يتم الدفع',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: student.status == 'paid'
                            ? const Color(0xFF16a34a)
                            : const Color(0xFFdc2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_left,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class StudentDetailScreen extends StatelessWidget {
  final Student student;

  const StudentDetailScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1b7c80),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            'المدفوعات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // بطاقة الملف الشخصي
              _buildProfileCard(),
              // سجل المدفوعات
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.grey[300],
            backgroundImage: AssetImage('assets/studentT.png'),
            onBackgroundImageError: (exception, stackTrace) {},
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  student.meta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[300]!,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'سجل الحركات المالية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (student.history.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'لا توجد معاملات',
                style: TextStyle(
                  color: Colors.grey[500],
                ),
              ),
            )
          else
            Column(
              children: student.history.map((payment) {
                return _buildPaymentRow(payment);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(PaymentHistory payment) {
    final isPaid = payment.type == 'paid';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[100]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isPaid ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                isPaid ? '✓' : '!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPaid
                      ? const Color(0xFF16a34a)
                      : const Color(0xFFdc2626),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  payment.date,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            payment.price,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isPaid
                  ? const Color(0xFF16a34a)
                  : const Color(0xFFdc2626),
            ),
          ),
        ],
      ),
    );
  }
}