import 'package:flutter/material.dart';

class DriverDetailsPage extends StatelessWidget {
  const DriverDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9FC),
        body: Column(
          children: [
            // الشعار في الأعلى مثل DashboardPage
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
                ],
              ),
            ),
            const SizedBox(height: 30),
            // بطاقة بيانات السائق
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    _buildInfoRow("الاسم:", "أحمد خالد"),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(),
                    ),
                    _buildInfoRow("رقم الباص:", "23"),
                  ],
                ),
              ),
            ),
            // لا يوجد كلمة "غائب" في الأسفل
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 18, color: Colors.black87)),
        const SizedBox(width: 40),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}