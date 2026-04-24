import 'package:flutter/material.dart';

class BusTrackingScreen extends StatelessWidget {
  const BusTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.notifications_none, color: Colors.black),
          ),
          Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.chat_bubble_outline, color: Colors.black),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔵 LOGO
            Image.asset(
              'assets/images/logo.png',
              height: 100,
            ),

            const SizedBox(height: 10),

            const Text(
              'عين رقيب',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // 🔵 TIMELINE CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 5,
                  )
                ],
              ),
              child: Column(
                children: const [
                  _Item("12:40", "انتهاء اليوم الدراسي"),
                  _Item("12:44", "تم تسجيل صعود الطالب للباص"),
                  _Item("12:51", "متبقي ثلاث دقائق للوصول"),
                  _Item("12:55", "وصل الطالب للمنزل"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔵 ICONS LINE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                Icon(Icons.apartment),
                Icon(Icons.accessible),
                Icon(Icons.hourglass_empty),
                Icon(Icons.home),
              ],
            ),

            const SizedBox(height: 20),

            // 🔵 MAP
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: const DecorationImage(
                  image: AssetImage('assets/images/map.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String time;
  final String text;

  const _Item(this.time, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}