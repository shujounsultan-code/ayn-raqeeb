import 'package:flutter/material.dart';
import 'widgets/back_button_widget.dart';
import 'students_screen.dart';
import 'profile_school_screen.dart';
import 'records_screen.dart';
import 'buses_page.dart';

// تأكدي من استيراد هذه الصفحة إذا كانت موجودة، أو احذفي الزر الخاص بها مؤقتًا
// import 'bus_fees_home.dart'; 

class HomeScreen extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const HomeScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

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
                    _buildHeader(),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'قائمة البيانات',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(child: _buildGrid(context)),
                    _buildBottomNavBar(context),
                  ],
                ),
              ),
            ),
            const Positioned(
              top: 40,
              right: 20,
              child: BackButtonWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.notifications_none_outlined, size: 28),
          Column(
            children: [
              Image.asset('assets/images/logobg.png', width: 92, height: 70, errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 50)),
              Text(schoolName, style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildCard(
          context, 
          'الباصات', 
          'assets/images/bus.png',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusesPage(
                schoolId: schoolId,
              ),
            ),
          ),
        ),
        _buildCard(
          context, 
          'الطالبات', 
          'assets/images/students.png', 
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StudentsScreen(
                schoolId: schoolId,
              ),
            ),
          ),
        ),
        _buildCard(
          context, 
          'الرسوم', 
          'assets/images/fees.png', 
          onTap: () {
            // Navigator.push(context, MaterialPageRoute(builder: (_) => const BusFeesHome()));
          },
        ),
        _buildCard(context, 'خريطة التتبع', 'assets/images/map.png'),
      ],
    );
  }

  Widget _buildCard(BuildContext context, String title, String imagePath, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE3E3E3)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 60, height: 60, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, size: 40)),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Tajawal')),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.person_outline, 'حسابي', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileSchoolScreen(schoolId: schoolId, schoolName: schoolName)));
          }),
          _buildNavItem(Icons.receipt_long_outlined, 'سجلاتي', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => RecordsScreen(schoolId: schoolId)));
          }),
          _buildNavItem(Icons.home_outlined, 'الرئيسية', selected: true),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool selected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? const Color(0xFF1B7C80) : Colors.grey),
          Text(label, style: TextStyle(color: selected ? const Color(0xFF1B7C80) : Colors.grey, fontFamily: 'Tajawal', fontSize: 12)),
        ],
      ),
    );
  }
}
