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

  void _showMadaPaymentSheet() {
    final cardController = TextEditingController();
    final nameController = TextEditingController();
    final dateController = TextEditingController();
    final cvvController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.only(
              right: 20,
              left: 20,
              top: 22,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'الدفع عبر مدى',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: mainColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: cardController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'رقم البطاقة',
                      hintText: '0000 0000 0000 0000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameController,
                    textAlign: TextAlign.right,
                    decoration: const InputDecoration(
                      labelText: 'اسم حامل البطاقة',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: cvvController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            hintText: '123',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: dateController,
                          keyboardType: TextInputType.datetime,
                          textAlign: TextAlign.right,
                          decoration: const InputDecoration(
                            labelText: 'تاريخ الانتهاء',
                            hintText: 'MM/YY',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showMessage('تم إرسال بيانات الدفع');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'تأكيد الدفع',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _madaLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 10, color: const Color(0xFF26A7DF)),
              const SizedBox(height: 4),
              Container(width: 38, height: 10, color: const Color(0xFF8DC63F)),
            ],
          ),
          const SizedBox(width: 8),
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مدى',
                style: TextStyle(
                  fontSize: 16,
                  height: 0.9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                'mada',
                style: TextStyle(
                  fontSize: 16,
                  height: 0.9,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String title, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Text(
            '$title: ',
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(color: valueColor ?? Colors.black),
            ),
          ),
        ],
      ),
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
                  textDirection: TextDirection.ltr,
                  children: [
                    InkWell(
                      onTap: () => _showMessage('التنبيهات'),
                      child: const Icon(Icons.notifications_none, size: 28),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => _showMessage('لا توجد رسائل حالياً'),
                      child: const Icon(Icons.chat_bubble_outline, size: 26),
                    ),
                    const Spacer(),
                    Column(
                      children: [
                        Image.asset(
                          'assets/images/logobg.png',
                          width: 90,
                          height: 64,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.school,
                            size: 40,
                            color: mainColor,
                          ),
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
                    textAlign: TextAlign.right,
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
                      return Center(child: Text('خطأ: ${stSnap.error}'));
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
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(n, textAlign: TextAlign.right),
                                  ),
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
                                  width: double.infinity,
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
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            schoolName,
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: mainColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        const Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'الرسوم',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            feeLabel,
                                            textAlign: TextAlign.right,
                                            style:
                                                const TextStyle(fontSize: 15),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: Colors.grey.shade300),
                              ),
                              child: const Directionality(
                                textDirection: TextDirection.rtl,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'الرسوم',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        '٢٠٠ ريال للفصل الواحد',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
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
                                _infoLine('الطالب', name),
                                _infoLine('الصف', grade),
                                const Divider(height: 20),
                                _infoLine(
                                  'حالة الدفع',
                                  feesPaid ? 'تم الدفع' : 'لم يتم الدفع',
                                  valueColor: feesPaid
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                ),
                                if (feesPaid)
                                  _infoLine('تاريخ الدفع', paymentDate),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Expanded(
                                child: InkWell(
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
                                          Text(
                                            'Pay',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(Icons.apple, size: 26),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: _showMadaPaymentSheet,
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: Center(child: _madaLogo()),
                                  ),
                                ),
                              ),
                            ],
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
                          const SizedBox(height: 24),
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