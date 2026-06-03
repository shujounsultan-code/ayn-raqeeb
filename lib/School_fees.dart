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

  static const Color primaryColor = Color(0xFF0F766E);
  static const Color backgroundColor = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Tajawal'),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: const Text(
              ' رسوم الحافلة',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 20,
              ),
            ),
            backgroundColor: primaryColor,
            centerTitle: true,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 12),

              // 1. حقل البحث
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'ابحث/ي عن اسم الطالب/ة...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(Icons.search, color: primaryColor),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),

              // 2. أزرار التصفية التلقائية الفورية (Chips)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildFilterChip('الكل', 'all')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('تم الدفع', 'paid')),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip('لم يتم الدفع', 'unpaid')),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 3. قائمة الطالبات المفلترة تلقائياً فورياً
              Expanded(child: _buildStudentsList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _paymentFilter == value;
    return ChoiceChip(
      label: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.white,
      shadowColor: Colors.black.withOpacity(0.05),
      elevation: isSelected ? 4 : 1,
      pressElevation: 2,
      padding: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.shade200,
        ),
      ),
      showCheckmark: false,
      onSelected: (_) {
        setState(() {
          _paymentFilter =
              value; // عند الضغط يتحدث الفلتر فوراً ويعيد بناء القائمة
        });
      },
    );
  }

  Widget _buildStudentsList() {
    // جلب كل طالبات المدرسة في Stream مباشر ومستمر
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('school_id', isEqualTo: widget.schoolId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد بيانات مسجلة',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          );
        }

        var docs = snapshot.data!.docs;

        // 🟢 الفلترة التلقائية الفورية بناءً على زر التصفية المختار
        if (_paymentFilter == 'paid') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            return (data['fees_paid'] == true);
          }).toList();
        } else if (_paymentFilter == 'unpaid') {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            return (data['fees_paid'] == false ||
                !data.containsKey('fees_paid'));
          }).toList();
        }

        // 🔵 تصفية إضافية بناءً على نص البحث إذا كتب المستخدم شيئاً
        if (_searchQuery.isNotEmpty) {
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>? ?? {};
            final name = (data['name'] ?? '').toString();
            return name.contains(_searchQuery);
          }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Text(
              'لا توجد طالبات في هذا التصنيف حالياً',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) => _StudentCard(doc: docs[index]),
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final DocumentSnapshot doc;
  const _StudentCard({required this.doc});

  static const Color primaryColor = Color(0xFF0F766E);
  static const Color paidColor = Color(0xFF10B981);
  static const Color unpaidColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final bool isPaid = data.containsKey('fees_paid')
        ? (data['fees_paid'] ?? false)
        : false;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PaymentHistoryScreen(studentId: doc.id, studentData: data),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: primaryColor.withOpacity(.1),
                  child: const Icon(Icons.person, color: primaryColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? 'اسم غير مسجل',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "الصف: ${data['grade'] ?? 'غير محدد'}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isPaid
                        ? paidColor.withOpacity(.12)
                        : unpaidColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPaid ? "مدفوع " : "غير مدفوع ",
                    style: TextStyle(
                      color: isPaid ? paidColor : unpaidColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentHistoryScreen extends StatelessWidget {
  final String studentId;
  final Map<String, dynamic> studentData;

  const PaymentHistoryScreen({
    super.key,
    required this.studentId,
    required this.studentData,
  });

  static const Color primaryColor = Color(0xFF0F766E);
  static const Color paidColor = Color(0xFF10B981);
  static const Color unpaidColor = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final bool isPaid = studentData['fees_paid'] ?? false;

    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'Tajawal'),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'سجل المدفوعات ',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            backgroundColor: primaryColor,
            centerTitle: true,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: primaryColor.withOpacity(0.1),
                        child: const Icon(
                          Icons.person_rounded,
                          color: primaryColor,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        studentData['name'] ?? 'اسم غير مسجل',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "الصف: ${studentData['grade'] ?? 'غير محدد'}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  "تفاصيل الفاتورة الحالية",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    children: [
                      _buildHistoryRow(
                        "نوع الرسوم:",
                        "رسوم اشتراك الحافلة المدرسية",
                      ),
                      const Divider(height: 24, thickness: 0.5),
                      _buildHistoryRow(
                        "المبلغ المقرر:",
                        "200 ريال",
                        isPrice: true,
                      ),
                      const Divider(height: 24, thickness: 0.5),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "حالة الدفع:",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isPaid
                                  ? paidColor.withOpacity(0.1)
                                  : unpaidColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isPaid
                                  ? 'تم السداد بنجاح '
                                  : 'لم يتم السداد بعد ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isPaid ? paidColor : unpaidColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 0.5),

                      _buildHistoryRow(
                        "تاريخ ووقت السداد:",
                        isPaid
                            ? (studentData['payment_date'] ?? 'تاريخ غير مسجل')
                            : '---',
                        textColor: isPaid ? Colors.black87 : Colors.grey,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPaid
                          ? Colors.orange.shade600
                          : paidColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      bool nextState = !isPaid;
                      String? nextDate = nextState
                          ? DateTime.now().toString().split(' ')[0]
                          : null;

                      await FirebaseFirestore.instance
                          .collection('students')
                          .doc(studentId)
                          .update({
                            'fees_paid': nextState,
                            'payment_date': nextDate,
                          });

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'تم تحديث السجل المالي للطالب بنجاح',
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: primaryColor,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      isPaid
                          ? "تغيير الحالة إلى غير مدفوع"
                          : "تأكيد استلام وتثبيت الدفع الآن",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    String label,
    String value, {
    bool isPrice = false,
    Color? textColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 15 : 13,
            fontWeight: isPrice ? FontWeight.bold : FontWeight.normal,
            color: textColor ?? (isPrice ? Colors.black87 : Colors.black87),
          ),
        ),
      ],
    );
  }
}
