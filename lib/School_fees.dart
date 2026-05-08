import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusFeesScreen extends StatefulWidget {
  final String schoolId;
  const BusFeesScreen({super.key, required this.schoolId});

  @override
  State<BusFeesScreen> createState() => _BusFeesScreenState();
}

class _BusFeesScreenState extends State<BusFeesScreen> {
  String _searchQuery = "";
  String _paymentFilter = 'all'; // 'all', 'paid', 'unpaid'

  final List<String> _gradeLevels = [
    'أول ابتدائي', 'ثاني ابتدائي', 'ثالث ابتدائي',
    'رابع ابتدائي', 'خامس ابتدائي', 'سادس ابتدائي',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        appBar: AppBar(
          title: const Text('رسوم الحافلة ', 
            style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B7C80),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // 1. حقل البحث
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث/ي عن اسم الطالب/ة...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF1B7C80)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                ),
              ),
            ),

            // 2. أزرار التصفية (الكل - تم الدفع - لم يتم الدفع)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFilterChip('الكل', 'all'),
                  _buildFilterChip('تم الدفع', 'paid'),
                  _buildFilterChip('لم يتم الدفع', 'unpaid'),
                ],
              ),
            ),

            const Divider(),

            // 3. عرض النتائج
            Expanded(
              child: _buildMainContent(),
            ),
          ],
        ),
      ),
    );
  }

  // دالة ذكية لتحديد ما يعرض في الشاشة الرئيسية
  Widget _buildMainContent() {
    // إذا كان المستخدم يبحث عن اسم معين
    if (_searchQuery.isNotEmpty) {
      return _buildFilteredStudentsList();
    }
    
    // إذا اختار المستخدم "تم الدفع" أو "لم يتم الدفع" نعرض الطالبات مباشرة
    if (_paymentFilter != 'all') {
      return _buildFilteredStudentsList();
    }

    // إذا كانت الحالة "الكل" نعرض قائمة الصفوف
    return _buildGradesList();
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _paymentFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontFamily: 'Tajawal')),
      selected: isSelected,
      selectedColor: const Color(0xFF1B7C80),
      onSelected: (bool selected) {
        setState(() { _paymentFilter = value; });
      },
    );
  }

  // عرض الصفوف الدراسية
  Widget _buildGradesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _gradeLevels.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(_gradeLevels[index], style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentsListByGradePage(
                    grade: _gradeLevels[index],
                    schoolId: widget.schoolId,
                    filter: 'all', // عند دخول صف معين من هنا، نعرض الكل
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // عرض قائمة الطالبات مباشرة بناءً على الفلتر (تم الدفع / لم يدفع)
  Widget _buildFilteredStudentsList() {
    Query query = FirebaseFirestore.instance.collection('students')
        .where('school_id', isEqualTo: widget.schoolId);

    if (_paymentFilter == 'paid') query = query.where('fees_paid', isEqualTo: true);
    if (_paymentFilter == 'unpaid') query = query.where('fees_paid', isEqualTo: false);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var docs = snapshot.data!.docs;
        
        // تصفية إضافية للبحث بالاسم إذا كان مكتوباً
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) => d['name'].toString().contains(_searchQuery)).toList();
        }

        if (docs.isEmpty) return const Center(child: Text('لا توجد طالبات ضمن هذا التصنيف'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (context, index) => _StudentTile(doc: docs[index]),
        );
      },
    );
  }
}

// الصفحة الفرعية (تعرض الطالبات عند الضغط على صف معين من قائمة الكل)
class StudentsListByGradePage extends StatelessWidget {
  final String grade;
  final String schoolId;
  final String filter;

  const StudentsListByGradePage({super.key, required this.grade, required this.schoolId, required this.filter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection('students')
        .where('school_id', isEqualTo: schoolId)
        .where('grade', isEqualTo: grade);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text('طالبات $grade'),
          backgroundColor: const Color(0xFF1B7C80),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return const Center(child: Text('لا توجد طالبات في هذا الصف'));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) => _StudentTile(doc: docs[index]),
            );
          },
        ),
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final DocumentSnapshot doc;
  const _StudentTile({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String studentId = doc.id;
    bool isPaid = data['fees_paid'] ?? false;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(data['name'] ?? '', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data['grade'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
            Text(
              isPaid ? "الحالة: تم دفع 200 ريال" : "الحالة: مطلوب سداد 200 ريال", 
              style: TextStyle(color: isPaid ? Colors.green : Colors.red, fontSize: 13, fontFamily: 'Tajawal')
            ),
          ],
        ),
        trailing: Icon(isPaid ? Icons.check_circle : Icons.error_outline, color: isPaid ? Colors.green : Colors.red),
        onTap: () => _showPaymentDialog(context, data, studentId, isPaid),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Map<String, dynamic> data, String studentId, bool isPaid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(data['name'], textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Tajawal')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 10),
            Text("قيمة الرسوم: 200 ريال", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("الحالة الحالية: ${isPaid ? 'مدفوعة' : 'غير مدفوعة'}"),
            if (isPaid) Text("تاريخ الدفع: ${data['payment_date'] ?? '---'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isPaid ? Colors.orange : Colors.green,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('students').doc(studentId).update({
                'fees_paid': !isPaid,
                'payment_date': !isPaid ? DateTime.now().toString().split(' ')[0] : null,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تحديث حالة الرسوم بنجاح'), backgroundColor: Color(0xFF1B7C80)),
              );
            },
            child: Text(isPaid ? "تغيير إلى لم يدفع" : "تأكيد استلام 200 ريال", style: const TextStyle(color: Colors.white)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إغلاق")),
        ],
      ),
    );
  }
}