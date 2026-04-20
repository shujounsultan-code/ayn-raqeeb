
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Column(
          children: [
            // الشريط العلوي (الساعة، الإشعارات، الشعار)
            Padding(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/images/logobg.png',
                        width: 60,
                        height: 60,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image, size: 40),
                      ),
                      const SizedBox(height: 1),
                      const Text('عين رقيب', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B7C80), fontSize: 13)),
                    ],
                  ),
                  // أيقونة الإشعارات
                  Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.black, size: 28),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            // الخريطة
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/map.webp',
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[300],
                    child: const Icon(Icons.map, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // قائمة الطلاب
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                children: [
                  _studentCard(
                    name: 'نورة سالم',
                    image: 'assets/images/student1.png',
                    bgColor: Color(0xFFF3E6F9),
                  ),
                  _studentCard(
                    name: 'شهد سلطان',
                    image: 'assets/student2.png',
                    bgColor: Color(0xFFFFE3D3),
                  ),
                  _studentCard(
                    name: 'لولو فهد',
                    image: 'assets/student3.png',
                    bgColor: Color(0xFFFFF3B0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentCard({required String name, required String image, required Color bgColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 32, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'الاسم : $name',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, String route) {
    return GestureDetector(
      onTap: () {
        if (route != '#') {
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: active ? Color(0xFF2dafb4) : Color(0xFF999999), size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: active ? Color(0xFF2dafb4) : Color(0xFF999999), fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
