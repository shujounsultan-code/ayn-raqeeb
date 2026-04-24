import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  static const Color teal = Color(0xFF1B7C80);
  static const Color darkBlue = Color(0xFF0B4C75);

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
                  const Row(
                    children: [
                      Icon(Icons.notifications_none, size: 34, color: Colors.black),
                      SizedBox(width: 18),
                      Icon(Icons.chat_bubble_outline, size: 34, color: Colors.black),
                    ],
                  ),
                  Image.asset(
                    'assets/images/logobg.png',
                    width: 78,
                    height: 78,
                    fit: BoxFit.contain,
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
              child: Column(
                children: const [
                  TimelineRow(time: '12:40', text: 'إنتهاء اليوم الدراسي', first: true),
                  TimelineRow(time: '12:44', text: 'تم تسجيل صعود الطالب للباص'),
                  TimelineRow(time: '12:51', text: 'متبقي ثلاث دقائق لوصول الطالب للمنزل'),
                  TimelineRow(time: '12:55', text: 'قد وصل الطالب للمنزل', last: true),
                ],
              ),
            ),

            const SizedBox(height: 34),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Row(
                children: const [
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
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFFEAF1F7),
                    child: Stack(
                      children: const [
                        Positioned.fill(child: FakeMap()),
                        Positioned(
                          left: 16,
                          top: 16,
                          child: MapInfoCard(),
                        ),
                        Positioned(
                          right: 65,
                          bottom: 95,
                          child: Icon(
                            Icons.directions_bus_filled,
                            size: 46,
                            color: Colors.black,
                          ),
                        ),
                        Positioned(
                          left: 120,
                          top: 150,
                          child: Text(
                            'Riyadh\nالرياض',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFD74735),
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined, size: 30),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/map.png',
              width: 32,
              height: 32,
            ),
            label: 'تتبع الباص',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              'assets/images/fees.png',
              width: 32,
              height: 32,
            ),
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
                    color: ChatScreenState.teal,
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
          backgroundColor: active ? ChatScreenState.teal : Colors.grey.shade200,
          child: Icon(
            icon,
            color: active ? Colors.white : ChatScreenState.darkBlue,
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

class MapInfoCard extends StatelessWidget {
  const MapInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riyadh', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 3),
          Text('Saudi Arabia', style: TextStyle(fontSize: 12)),
          SizedBox(height: 8),
          Text(
            'View larger map',
            style: TextStyle(color: Colors.blue, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class FakeMap extends StatelessWidget {
  const FakeMap({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MapPainter(),
      child: Container(),
    );
  }
}

class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 22
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final roadBorder = Paint()
      ..color = const Color(0xFFD4DEE8)
      ..strokeWidth = 26
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    void road(List<Offset> points) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, roadBorder);
      canvas.drawPath(path, roadPaint);
    }

    road([
      Offset(-30, size.height * .65),
      Offset(size.width * .35, size.height * .45),
      Offset(size.width + 40, size.height * .25),
    ]);

    road([
      Offset(size.width * .70, -20),
      Offset(size.width * .62, size.height * .35),
      Offset(size.width * .70, size.height + 30),
    ]);

    road([
      Offset(-20, size.height * .25),
      Offset(size.width * .30, size.height * .35),
      Offset(size.width * .55, size.height * .75),
    ]);

    road([
      Offset(size.width * .10, size.height + 20),
      Offset(size.width * .35, size.height * .70),
      Offset(size.width * .55, size.height * .55),
    ]);

    final smallRoad = Paint()
      ..color = const Color(0xFFDDE6EF)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 7; i++) {
      final y = size.height * (0.12 + i * 0.12);
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 55), smallRoad);
    }

    final blue = Paint()..color = Colors.blue.shade300;
    final pink = Paint()..color = Colors.pink.shade300;

    canvas.drawCircle(Offset(size.width * .78, size.height * .18), 8, blue);
    canvas.drawCircle(Offset(size.width * .40, size.height * .78), 8, blue);
    canvas.drawCircle(Offset(size.width * .28, size.height * .70), 8, pink);
    canvas.drawCircle(Offset(size.width * .55, size.height * .67), 8, pink);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}