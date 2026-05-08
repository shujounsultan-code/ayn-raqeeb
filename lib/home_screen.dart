import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Stream<int> _getCollectionCount(String collectionName) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Widget _buildStatCard(Stream<int> stream, String title) {
    return Expanded(
      child: StreamBuilder<int>(
        stream: stream,
        builder: (context, snapshot) {
          final number = snapshot.hasData ? snapshot.data.toString() : '...';

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B7C80),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    String imagePath, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFFE8EEEE),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      width: 42,
                      height: 42,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173B3D),
                  ),
                ),
              ],
            ),
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE7F6F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: selected ? const Color(0xFF1B7C80) : Colors.grey,
              size: 24,
            ),
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

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(top: 38),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE3EFEF),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6F7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/images/logobg.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schoolName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF173B3D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'مرحبًا بك في لوحة التحكم',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1B7C80),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomItem(
            Icons.person_outline_rounded,
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
            Icons.receipt_long_rounded,
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
            Icons.home_rounded,
            'الرئيسية',
            selected: true,
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
        backgroundColor: const Color(0xFFF7F9FC),
        body: Stack(
          children: [
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _buildStatCard(
                            _getCollectionCount('students'),
                            'الطالبات',
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            _getCollectionCount('buses'),
                            'الباصات',
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            _getCollectionCount('trips'),
                            'الرحلات',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          const Text(
                            'الخدمات',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF173B3D),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7F7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '4 خدمات',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1B7C80),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 420,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final bool isWide = constraints.maxWidth > 420;

                            return GridView.count(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: isWide ? 0.95 : 0.82,
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
                      _buildBottomNav(context),
                    ],
                  ),
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