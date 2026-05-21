import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => BusTrackingScreenState();
}

class BusTrackingScreenState extends State<BusTrackingScreen> {
  static const Color teal = Color(0xFF1B7C80);
  static const Color darkBlue = Color(0xFF0B4C75);

  static const LatLng schoolLocation = LatLng(21.4373, 40.5127);
  static const LatLng busLocation = LatLng(21.4450, 40.5180);

  int currentIndex = 1;

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          showMessage('فتح صفحة التنبيهات');
                        },
                        child: const Icon(
                          Icons.notifications_none,
                          size: 28,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 14),
                      InkWell(
                        onTap: () {
                          showMessage('فتح صفحة الرسائل');
                        },
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 28,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logobg.png',
                        width: 95,
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const Text(
                          'عين رقيب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Column(
                children: [
                  TimelineRow(time: '12:40', text: 'إنتهاء اليوم الدراسي', first: true),
                  TimelineRow(time: '12:44', text: 'تم تسجيل صعود الطالب للباص'),
                  TimelineRow(time: '12:51', text: 'متبقي ثلاث دقائق لوصول الطالب للمنزل'),
                  TimelineRow(time: '12:55', text: 'قد وصل الطالب للمنزل', last: true),
                ],
              ),
            ),
            const SizedBox(height: 34),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                children: [
                  StepItem(icon: Icons.apartment, time: '12:40'),
                  StepConnector(),
                  StepItem(icon: Icons.accessible, time: '12:44'),
                  StepConnector(),
                  StepItem(icon: Icons.hourglass_empty, time: '12:51'),
                  StepConnector(),
                  StepItem(icon: Icons.home, time: '12:55', active: true),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: const MapOptions(
                      initialCenter: schoolLocation,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.ayn_raqeeb',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: schoolLocation,
                            width: 110,
                            height: 110,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: teal, width: 2),
                                color: teal.withOpacity(0.12),
                              ),
                              child: const Center(
                                child: Text(
                                  '🏫',
                                  style: TextStyle(fontSize: 40),
                                ),
                              ),
                            ),
                          ),
                          Marker(
                            point: busLocation,
                            width: 50,
                            height: 50,
                            child: const Icon(
                              Icons.directions_bus_filled,
                              color: teal,
                              size: 44,
                            ),
                          ),
                          Marker(
                            point: const LatLng(21.4390, 40.5140),
                            width: 12,
                            height: 12,
                            child: const CircleAvatar(
                              backgroundColor: teal,
                              radius: 5,
                            ),
                          ),
                          Marker(
                            point: const LatLng(21.4410, 40.5155),
                            width: 12,
                            height: 12,
                            child: const CircleAvatar(
                              backgroundColor: teal,
                              radius: 5,
                            ),
                          ),
                          Marker(
                            point: const LatLng(21.4430, 40.5168),
                            width: 12,
                            height: 12,
                            child: const CircleAvatar(
                              backgroundColor: teal,
                              radius: 5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 13,
        unselectedFontSize: 13,
        iconSize: 30,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'تتبع الباص',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'الرسوم',
          ),
        ],
      ),
    );
  }
}

class TimelineRow extends StatelessWidget {
  final String time;
  final String text;
  final bool first;
  final bool last;

  const TimelineRow({
    super.key,
    required this.time,
    required this.text,
    this.first = false,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          SizedBox(
            width: 22,
            child: Column(
              children: [
                if (!first)
                  Expanded(child: Container(width: 2, color: Colors.grey)),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    color: BusTrackingScreenState.teal,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Text(
            time,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 15.5),
            ),
          ),
        ],
      ),
    );
  }
}

class StepItem extends StatelessWidget {
  final IconData icon;
  final String time;
  final bool active;

  const StepItem({
    super.key,
    required this.icon,
    required this.time,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 27,
          backgroundColor: active
              ? BusTrackingScreenState.teal
              : Colors.grey.shade200,
          child: Icon(
            icon,
            color: active ? Colors.white : BusTrackingScreenState.darkBlue,
            size: 27,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          time,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class StepConnector extends StatelessWidget {
  const StepConnector({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(bottom: 34),
        height: 3,
        color: Colors.black,
      ),
    );
  }
}