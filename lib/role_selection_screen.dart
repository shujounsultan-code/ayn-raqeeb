import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'widgets/back_button_widget.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),

      body: Stack(
        children: [
          SafeArea(
            child: Center(
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

                      _buildButton('المدرسة', context),
                      const SizedBox(height: 16),

                      _buildButton('ولي الأمر', context),
                      const SizedBox(height: 16),

                      _buildButton('السائق', context),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const BackButtonWidget(), // 🔥 زر الرجوع
        ],
      ),
    );
  }

  Widget _buildButton(String text, BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () {
          if (text == 'ولي الأمر') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        },
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
    );
  }
}