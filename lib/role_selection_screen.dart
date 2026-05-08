import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'widgets/back_button_widget.dart';
import 'driver_login_screen.dart';
import 'my_screens/parent_login_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _pressedButton;

  void _goToScreen(String text, Widget screen) async {
    setState(() {
      _pressedButton = text;
    });

    await Future.delayed(const Duration(milliseconds: 90));

    setState(() {
      _pressedButton = null;
    });

    await Future.delayed(const Duration(milliseconds: 120));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logobg.png',
                          width: 200,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'عين رقيب',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B7C80),
                          ),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'اختر فئتك للاستمرار',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildButton(
                          text: 'المدرسة',
                          screen: const LoginScreen(),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          text: 'ولي الأمر',
                          screen: const ParentLoginScreen(),
                        ),
                        const SizedBox(height: 16),
                        _buildButton(
                          text: 'السائق',
                          screen: const DriverLoginScreen(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const BackButtonWidget(),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required Widget screen,
  }) {
    final bool isPressed = _pressedButton == text;

    return AnimatedScale(
      scale: isPressed ? 0.94 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () => _goToScreen(text, screen),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B7C80),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}