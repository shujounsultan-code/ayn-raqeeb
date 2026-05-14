import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../parent_session.dart';
import 'parent_student_scope.dart';

class FeesPaymentScreen extends StatefulWidget {
  const FeesPaymentScreen({super.key});

  @override
  State<FeesPaymentScreen> createState() => _FeesPaymentScreenState();
}

class _FeesPaymentScreenState extends State<FeesPaymentScreen> {
  static const Color mainColor = Color(0xFF1B7C80);

  String? _selectedStudentDocId;

  String _effectiveStudentDocId(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return '';
    final sel = _selectedStudentDocId;
    if (sel != null && docs.any((d) => d.id == sel)) return sel;
    return docs.first.id;
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text, textAlign: TextAlign.right)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = ParentSession.schoolIdFromParent ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => _showMessage('التنبيهات'),
                      child: const Icon(Icons.notifications_none, size: 28),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/logobg.png',
                          width: 90,
                          height: 64,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.school, size: 40, color: mainColor),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'عين رقيب',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    ParentSession.parentName ?? 'ولي الأمر',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                  stream: parentLinkedStudentsStream(),
                  builder: (context, stSnap) {
                    if (stSnap.connectionState == ConnectionState.waiting &&
                        !stSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (stSnap.hasError) {
                      return Center(
                        child: Text('خطأ: ${stSnap.error}'),
                      );
                    }
                    final docs = stSnap.data ?? [];
                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'لا يوجد طالب مرتبط لعرض الرسوم.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final effId = _effectiveStudentDocId(docs);
                    final st = docs.firstWhere((d) => d.id == effId);
                    final stData = st.data() ?? {};
                    final feesPaid = stData['fees_paid'] == true;
                    final paymentDate =
                        stData['payment_date']?.toString() ?? '—';
                    final grade = stData['grade']?.toString() ?? '—';
                    final name = stData['name']?.toString() ?? '—';

                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (docs.length > 1)
                            DropdownButtonFormField<String>(
                              value: effId,
                              decoration: const InputDecoration(
                                labelText: 'الطالب',
                                border: OutlineInputBorder(),
                              ),
                              items: docs.map((d) {
                                final n =
                                    d.data()?['name']?.toString() ?? d.id;
                                return DropdownMenuItem(
                                  value: d.id,
                                  child: Text(n),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() => _selectedStudentDocId = v);
                                }
                              },
                            ),
                          if (docs.length > 1) const SizedBox(height: 12),
                          if (schoolId.isNotEmpty)
                            StreamBuilder<
                                DocumentSnapshot<Map<String, dynamic>>>(
                              stream: FirebaseFirestore.instance
                                  .collection('schools')
                                  .doc(schoolId)
                                  .snapshots(),
                              builder: (context, sch) {
                                final schData = sch.data?.data();
                                final schoolName =
                                    schData?['school_name']?.toString() ??
                                        'المدرسة';
                                final feeAmount = schData?['bus_fee_amount'] ??
                                    schData?['semester_fee'] ??
                                    200;
                                final feeLabel = feeAmount is num
                                    ? '${feeAmount.toString()} ريال للفصل'
                                    : feeAmount.toString();

                                return Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        schoolName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: mainColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'الرسوم',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        feeLabel,
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'الرسوم',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    '٢٠٠ ريال للفصل الواحد',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('الطالب: $name'),
                                Text('الصف: $grade'),
                                const Divider(height: 20),
                                Text(
                                  feesPaid
                                      ? 'حالة الدفع: تم الدفع'
                                      : 'حالة الدفع: لم يتم الدفع',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: feesPaid
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                  ),
                                ),
                                if (feesPaid)
                                  Text('تاريخ الدفع: $paymentDate'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: () =>
                                _showMessage('الدفع الإلكتروني قيد التطوير'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.apple, size: 26),
                                    SizedBox(width: 6),
                                    Text(
                                      'Pay',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () =>
                                _showMessage('تواصل مع المدرسة لإتمام الدفع'),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: mainColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text(
                                  'ادفع الآن',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
