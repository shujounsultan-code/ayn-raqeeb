import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const Color mainColor = Color(0xFF1B7C80);

  String? selectedStudent;
  String status = '';
  int currentIndex = 0;

  final List<String> students = ['شهد سلطان', 'نورة سالم', 'ريم أحمد'];

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, textAlign: TextAlign.right),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void registerStatus(String newStatus) {
    setState(() => status = newStatus);

    if (newStatus == 'حاضر') {
      showMessage('تم تسجيل حضور الطالب وإبلاغ المدرسة والباص');
    } else {
      showMessage('تم تسجيل غياب الطالب وإبلاغ المدرسة والباص');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => showMessage('فتح التنبيهات'),
                    child: const Icon(Icons.notifications_none, size: 28),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => showMessage('فتح الرسائل'),
                    child: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline, size: 30),
                        Text(
                          '?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logobg.png',
                        width: 95,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const Text(
                          'عين رقيب',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: mainColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 72),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 160,
                height: 34,
                margin: const EdgeInsets.only(right: 38),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStudent,
                    hint: const Text('اسم الطالب', style: TextStyle(fontSize: 14)),
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    alignment: Alignment.centerRight,
                    items: students.map((student) {
                      return DropdownMenuItem(
                        value: student,
                        child: Text(student),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => selectedStudent = value);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                height: 235,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          'assets/images/student.png',
                          width: 140,
                          height: 68,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('شهد سلطان'),
                            SizedBox(height: 16),
                            Text('ثالث متوسط'),
                            SizedBox(height: 16),
                            Text('21'),
                          ],
                        ),
                        SizedBox(width: 22),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            LabelText(text: 'الاسم'),
                            SizedBox(height: 16),
                            LabelText(text: 'الصف'),
                            SizedBox(height: 16),
                            LabelText(text: 'رقم الباص'),
                          ],
                        ),
                        SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 34),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => registerStatus('غائب'),
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: status == 'غائب'
                              ? Colors.red.shade700
                              : Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'غائب',
                            style: TextStyle(color: Colors.white, fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => registerStatus('حاضر'),
                      child: Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: status == 'حاضر'
                              ? Colors.green.shade700
                              : Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'حاضر',
                            style: TextStyle(color: Colors.white, fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() => currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: mainColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'تتبع الباص',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'الرسوم',
          ),
        ],
      ),
    );
  }
}

class LabelText extends StatelessWidget {
  final String text;

  const LabelText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: TextDirection.rtl,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text(':'),
      ],
    );
  }
}