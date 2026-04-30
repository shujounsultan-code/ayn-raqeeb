import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'welcome_screen.dart';

// واجهات السائق
import 'dashboard.dart';
import 'qr_code.dart';
import 'driver_details.dart';

// واجهات ولي الأمر
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WelcomeScreen(),
    );
  }
}

// ==================== تنقل السائق ====================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2;

  final List<Widget> _pages = const [
    DriverDetailsPage(),
    QrCodePage(),
    DashboardPage(),
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
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'حسابي'),
            BottomNavigationBarItem(icon: Icon(Icons.camera_alt_outlined), label: 'الكاميرا'),
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'الرئيسية'),
          ],
        ),
      ),
    );
  }
}

// ==================== تنقل ولي الأمر ====================
class ParentNavigation extends StatefulWidget {
  const ParentNavigation({super.key});

  @override
  State<ParentNavigation> createState() => _ParentNavigationState();
}

class _ParentNavigationState extends State<ParentNavigation> {
  int _selectedIndex = 0;

  double aiLeft = 300;
  double aiTop = 560;

  final List<Widget> _pages = const [
    AttendanceScreen(),
    BusTrackingScreen(),
    FeesPaymentScreen(),
  ];

  void _openAiChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AiChatScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ClipRect(
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: -95,
                  child: _pages[_selectedIndex],
                ),
              ],
            ),
          ),

          Positioned(
            left: aiLeft,
            top: aiTop,
            child: Draggable(
              feedback: _aiButton(),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                setState(() {
                  aiLeft = details.offset.dx;
                  aiTop = details.offset.dy;
                });
              },
              child: GestureDetector(
                onTap: _openAiChat,
                child: _aiButton(),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: const Color(0xFF5BA199),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle_outline),
            label: 'الحضور',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            label: 'تتبع الباص',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: 'الرسوم',
          ),
        ],
      ),
    );
  }

  Widget _aiButton() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF5BA199),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black26,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.smart_toy_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}