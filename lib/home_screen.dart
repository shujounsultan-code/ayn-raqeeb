import 'package:flutter/material.dart';
import 'widgets/back_button_widget.dart';
import 'students_screen.dart';
import 'profile_school_screen.dart';
import 'records_screen.dart';

class HomeScreen extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const HomeScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  Widget _buildCard(
    BuildContext context,
    String title,
    String imagePath, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFE3E3E3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Image.asset(
                    imagePath,
                    width: 62,
                    height: 62,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(
    IconData icon,
    String title, {
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: Column(
                  children: [
                    Row(
                      textDirection: TextDirection.ltr,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.notifications_none_outlined,
                          color: Colors.black87,
                          size: 28,
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Image.asset(
                              'assets/images/logobg.png',
                              width: 92,
                              height: 70,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              schoolName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'قائمة البيانات',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final bool isWide = constraints.maxWidth > 420;

                          return GridView.count(
                            physics: const BouncingScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: isWide ? 1.08 : 0.95,
                            children: [
                              _buildCard(
                                context,
                                'الباصات',
                                'assets/images/bus.png',
                              ),
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
                              _buildCard(
                                context,
                                'الرسوم',
                                'assets/images/fees.png',
                              ),
                              _buildCard(
                                context,
                                'خريطة التتبع',
                                'assets/images/map.png',
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 10,
                        right: 12,
                        left: 12,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFEAEAEA),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildBottomItem(
                            Icons.person_outline,
                            'حسابي',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfileSchoolScreen(
                                    schoolId: schoolId,
                                    schoolName: schoolName,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildBottomItem(
                            Icons.receipt_long_outlined,
                            'سجلاتي',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RecordsScreen(
                                    schoolId: schoolId,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildBottomItem(
                            Icons.home_outlined,
                            'الرئيسية',
                            selected: true,
                          ),
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