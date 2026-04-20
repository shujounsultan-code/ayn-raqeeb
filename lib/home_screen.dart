import 'package:flutter/material.dart';
import 'widgets/back_button_widget.dart';
import 'students_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _buildCard(BuildContext context, String title, String imagePath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2E2E2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 55,
              height: 55,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomItem(IconData icon, String title, {bool selected = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: selected ? const Color(0xFF1B7C80) : Colors.grey,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: selected ? const Color(0xFF1B7C80) : Colors.grey,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.notifications_none,
                          color: Colors.black87,
                          size: 26,
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Image.asset(
                              'assets/images/logobg.png',
                              width: 110,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 0),
                            const Text(
                              'عين رقيب',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'قائمة البيانات',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 1.05,
                        children: [
                          _buildCard(context, 'الباصات', 'assets/images/bus.png'),
                          _buildCard(
                            context,
                            'الطالبات',
                            'assets/images/students.png',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentsScreen(),
                              ),
                            ),
                          ),
                          _buildCard(context, 'الرسوم', 'assets/images/fees.png'),
                          _buildCard(context, 'خريطة التتبع', 'assets/images/map.png'),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBottomItem(Icons.person_outline, 'حسابي'),
                          _buildBottomItem(Icons.receipt_long_outlined, 'سجلاتي'),
                          _buildBottomItem(Icons.home_outlined, 'الرئيسية', selected: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const BackButtonWidget(),
          ],
        ),
      ),
    );
  }
}
