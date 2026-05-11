import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'driver_session.dart';

class DriverDetailsPage extends StatelessWidget {
  const DriverDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverSession.currentDriver;
    // استخراج البيانات
    String createdAt = '--';
    String status = '--';
    String fullName = '--';
    String firstName = '--';
    String phone = '--';
    if (driver != null) {
      // الاسم الكامل
      if (driver['driver_name'] != null) {
        fullName = driver['driver_name'].toString();
        // استخراج الاسم الأول فقط
        final parts = fullName.trim().split(' ');
        firstName = parts.isNotEmpty ? parts[0] : fullName;
      }
      // رقم الجوال
      if (driver['phone_number'] != null) {
        phone = driver['phone_number'].toString();
      } else if (driver['phone'] != null) {
        phone = driver['phone'].toString();
      }
      // تاريخ الإنشاء (Firestore Timestamp)
      if (driver['created_at'] != null) {
        final ts = driver['created_at'];
        if (ts is DateTime) {
          createdAt = '${ts.year}-${ts.month.toString().padLeft(2, '0')}-${ts.day.toString().padLeft(2, '0')}';
        } else if (ts is Timestamp) {
          final dt = ts.toDate();
          createdAt = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        } else if (ts is String) {
          createdAt = ts.split('T').first;
        }
      }
      // حالة الحساب
      if (driver['status'] != null) {
        status = driver['status'].toString() == 'active' || driver['status'] == true ? 'نشط' : 'غير نشط';
      }
    }
    // استخراج رقم الباص الخاص بالسائق
    final busNumber = driver != null ? driver['bus_number'] : null;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== بطاقة البروفايل العلوية =====
                Padding(
                  padding: const EdgeInsets.only(top: 28, right: 18, left: 18, bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 10),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // صورة السائق (أفاتار)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF5BA199),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.directions_bus_filled_rounded, color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 14),
                          // الاسم الأول فقط
                          Text(
                            firstName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Color(0xFF222B45)),
                          ),
                          const SizedBox(height: 4),
                          // الوصف
                          const Text(
                            'سائق حافلة مدرسية',
                            style: TextStyle(fontSize: 15, color: Color(0xFF8F9BB3)),
                          ),
                          const SizedBox(height: 10),
                          // حالة النشاط
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8FDE8),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: const [
                                    Text('متاح ونشط', style: TextStyle(color: Color(0xFF16a34a), fontWeight: FontWeight.bold, fontSize: 15)),
                                    SizedBox(width: 6),
                                    CircleAvatar(radius: 5, backgroundColor: Color(0xFF16a34a)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ...existing code...
                // عنوان المعلومات الشخصية
                Padding(
                  padding: const EdgeInsets.only(top: 24, right: 18, left: 18, bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.assignment_ind, color: Color(0xFFb0b8c1), size: 22),
                      const SizedBox(width: 7),
                      const Text('المعلومات الشخصية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF222B45))),
                    ],
                  ),
                ),
                // بطاقة المعلومات الشخصية (الاسم الكامل، رقم الجوال)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _profileRow(
                          value: fullName,
                          label: 'الاسم الكامل',
                          icon: Icons.person,
                          iconBg: const Color(0xFFF3F6FD),
                          iconColor: Color(0xFF7B61FF),
                          bold: true,
                        ),
                        _divider(),
                        _profileRow(
                          value: phone,
                          label: 'رقم الجوال',
                          icon: Icons.phone_android,
                          iconBg: const Color(0xFFF3FDE8),
                          iconColor: Color(0xFF7DD36F),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                // ...existing code...
                // عنوان معلومات الحساب
                Padding(
                  padding: const EdgeInsets.only(top: 24, right: 18, left: 18, bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.settings, color: Color(0xFFb0b8c1), size: 22),
                      const SizedBox(width: 7),
                      const Text('معلومات الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF222B45))),
                    ],
                  ),
                ),
                // بطاقة معلومات الحساب (تاريخ الإنشاء، نوع الحساب)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // تاريخ الإنشاء
                        _profileRow(
                          value: createdAt,
                          label: 'تاريخ إنشاء الحساب',
                          icon: Icons.calendar_month,
                          iconBg: const Color(0xFFF3F6FD),
                          iconColor: Color(0xFF7B61FF),
                          bold: true,
                        ),
                        _divider(),
                        // نوع الحساب
                        _profileRow(
                          value: 'سائق',
                          label: 'نوع الحساب',
                          icon: Icons.vpn_key,
                          iconBg: const Color(0xFFF3FDE8),
                          iconColor: Color(0xFF7DD36F),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // زر تسجيل الخروج
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF6F6),
                        foregroundColor: const Color(0xFFdc2626),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFFFE2E2)),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.logout, color: Color(0xFFdc2626)),
                      label: const Text(
                        'تسجيل الخروج',
                        style: TextStyle(fontSize: 17, color: Color(0xFFdc2626), fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        DriverSession.currentDriver = null;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => WelcomeScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // ===== قائمة الطلاب المرتبطين بنفس الباص =====
                if (busNumber != null && busNumber.toString().isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    child: Text(
                      'الطلاب المسجلون في باص رقم $busNumber:',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1B7C80)),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('students')
                          .where('school_id', isEqualTo: (driver?['school_id']?.toString().trim() ?? ''))
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('حدث خطأ أثناء تحميل الطلاب', style: TextStyle(color: Colors.red.shade700));
                        }
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final allStudents = snapshot.data!.docs;
                        final wantedBus = busNumber.toString().trim();
                        final students = allStudents.where((d) {
                          final data = d.data();
                          final sBus = (data['bus'] ?? '').toString().trim();
                          return sBus == wantedBus;
                        }).toList();
                        if (students.isEmpty) {
                          return const Text('لا يوجد طلاب مسجلون في هذا الباص حالياً.');
                        }
                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: students.length,
                          separatorBuilder: (context, i) => const Divider(),
                          itemBuilder: (context, i) {
                            final student = students[i].data();
                            return ListTile(
                              leading: const Icon(Icons.person, color: Color(0xFF1B7C80)),
                              title: Text(student['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('الصف: ${student['grade'] ?? 'غير محدد'}'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() => const Divider(height: 0, thickness: 1, color: Color(0xFFF3F3F3));

  Widget _profileRow({
    required String value,
    required String label,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    bool bold = false,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 22), // زيادة المسافة العمودية
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                  color: valueColor ?? const Color(0xFF222B45),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF8F9BB3))),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(7),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ],
      ),
    );
  }
}
