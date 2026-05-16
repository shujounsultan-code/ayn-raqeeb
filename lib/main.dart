import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'welcome_screen.dart';

// واجهات السائق
import 'dashboard.dart';
import 'qr_code.dart';
import 'driver_details.dart';
import 'services/bus_location_service.dart';

// واجهات ولي الأمر
import 'my_screens/attendance_screen.dart';
import 'my_screens/bus_tracking_screen.dart';
import 'my_screens/fees_payment_screen.dart';
import 'my_screens/ai_chat_screen.dart';
import 'parent_session.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
  void initState() {
    super.initState();
    BusLocationService.start();
  }

  @override
  void dispose() {
    BusLocationService.stop();
    super.dispose();
  }

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

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _parentNotifSub;

  final List<Widget> _pages = const [
    AttendanceScreen(),
    BusTrackingScreen(),
    FeesPaymentScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _attachParentNotificationListener();
  }

  void _attachParentNotificationListener() {
    final pid = ParentSession.parentBusinessId;
    if (pid == null || pid.isEmpty) return;
    _parentNotifSub = FirebaseFirestore.instance
        .collection('parent_notifications')
        .where('parent_id', isEqualTo: pid)
        .snapshots()
        .listen(_onParentNotifications);
  }

  void _onParentNotifications(QuerySnapshot<Map<String, dynamic>> snap) {
    if (!mounted) return;
    final started = ParentSession.sessionStartedAt;
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final doc = change.doc;
      final data = doc.data();
      if (data == null) continue;
      if (data['read'] == true) continue;
      final ts = data['created_at'];
      if (started != null && ts is Timestamp) {
        if (!ts
            .toDate()
            .isAfter(started.subtract(const Duration(seconds: 3)))) {
          continue;
        }
      }
      final body = data['body']?.toString() ??
          data['title']?.toString() ??
          'تنبيه جديد';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body, textAlign: TextAlign.right),
          duration: const Duration(seconds: 5),
        ),
      );
      doc.reference.update({'read': true});
    }
  }

  @override
  void dispose() {
    _parentNotifSub?.cancel();
    super.dispose();
  }

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