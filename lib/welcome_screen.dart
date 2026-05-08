import 'package:flutter/material.dart';
import 'role_selection_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double _buttonScale = 1.0;

  void _goToNextScreen() async {
    setState(() {
      _buttonScale = 0.94;
    });

    await Future.delayed(const Duration(milliseconds: 90));

    setState(() {
      _buttonScale = 1.0;
    });

    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RoleSelectionScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Image.asset(
                      'assets/images/logobg.png',
                      width: 260,
                      height: 240,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'عين رقيب',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7C80),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'أمان أبنائك بعد الله يبدأ من هنا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'تتبّع · اطمئن · تواصل',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 40),

                  AnimatedScale(
                    scale: _buttonScale,
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goToNextScreen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7C80),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'ابدأ',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}