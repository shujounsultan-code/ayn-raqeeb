import 'package:flutter/material.dart';

class FeesPaymentScreen extends StatefulWidget {
  const FeesPaymentScreen({super.key});

  @override
  State<FeesPaymentScreen> createState() => _FeesPaymentScreenState();
}

class _FeesPaymentScreenState extends State<FeesPaymentScreen> {
  int currentIndex = 2;
  static const Color mainColor = Color(0xFF1B7C80);

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
            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      showMessage('فتح صفحة التنبيهات');
                    },
                    child: const Icon(Icons.notifications_none, size: 28),
                  ),

                  const SizedBox(width: 12),

                  InkWell(
                    onTap: () {
                      showMessage('فتح صفحة الرسائل');
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline, size: 28),
                        Positioned(
                          top: 6,
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  Column(
                    children: [
                      Image.asset(
                        'assets/images/logobg.png',
                        width: 95,
                        height: 70,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'عين رقيب',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 22,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'الرسوم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '٢٠٠ ريال للفصل الواحد',
                      style: TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 80),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: InkWell(
                onTap: () {
                  showMessage('تم الضغط على Apple Pay');
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apple, size: 28),
                        SizedBox(width: 6),
                        Text(
                          'Pay',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: InkWell(
                onTap: () {
                  showMessage('تم الضغط على ادفع الآن');
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: mainColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'ادفع الآن',
                      style: TextStyle(color: Colors.white, fontSize: 22),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),
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
        selectedItemColor: mainColor,
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