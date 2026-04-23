import 'package:flutter/material.dart';
import 'widgets/back_button_widget.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  final String schoolId;
  final String schoolName;

  const SettingsScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  Widget _item(BuildContext context, String title, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 17),
            ),
          ),
          Icon(icon, color: const Color(0xFF1B7C80)),
        ],
      ),
    );
  }

  Widget _logout(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: const Center(
          child: Text(
            'تسجيل الخروج',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'الإعدادات',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _item(context, 'تغيير كلمة المرور', Icons.lock_outline),
                    _item(context, 'اللغة', Icons.language_outlined),
                    _item(context, 'الإشعارات', Icons.notifications_outlined),
                    _item(context, 'حول النظام', Icons.info_outline),
                    const Spacer(),
                    _logout(context),
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