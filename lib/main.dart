import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 

import 'welcome_screen.dart';
import 'dashboard.dart';
import 'qr_code.dart';
import 'driver_details.dart';

// ✅ 
import 'my_screens/attendance_screen.dart';
import 'my_screens/bus_tracking_screen.dart';
import 'my_screens/fees_payment_screen.dart';
import 'my_screens/ai_chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(), // 
    );
  }
}

// ---------------- MainNavigation ----------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // يفتح على "الرئيسية"

  final List<Widget> _pages = [
    const DriverDetailsPage(),   // حسابي (شغل البنات)
    const QrCodePage(),          // الكاميرا (شغل البنات)
    const DashboardPage(),       // الرئيسية (شغل البنات)

    // 👇 شغلك (مضاف بدون تخريب)
    const BusTrackingScreen(),
    const FeesPaymentScreen(),
    const AttendanceScreen(),
    const AiChatScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: _pages[_selectedIndex],

        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: const Color(0xFF1B7C80),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'حسابي',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt_outlined),
              label: 'الكاميرا',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'الرئيسية',
            ),

            // 👇 إضافاتك
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              label: 'تتبع الباص',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'الرسوم',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.check_circle_outline),
              label: 'الحضور',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'الشات',
            ),
          ],
        ),
      ),
    );
  }
}