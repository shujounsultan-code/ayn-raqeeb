import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'dashboard.dart';
import 'qr_code.dart';
import 'driver_details.dart';
import 'my_screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainNavigation(),
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
  int _selectedIndex = 2;

  final List<Widget> _pages = [
    const DriverDetailsPage(),
    const QrCodePage(),
    const DashboardPage(),
    const ChatScreen(), // 👈 واجهتك هنا بدون ما تخرب شيء
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
          selectedItemColor: const Color(0xFF5BA199),
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
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'الشات', // 👈 زر واجهتك
            ),
          ],
        ),
      ),
    );
  }
}