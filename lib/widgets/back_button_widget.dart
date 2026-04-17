import 'package:flutter/material.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 6, // نفس مستوى الهيدر
      left: 4,
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 22,
          color: Color(0xFF1B7C80), // لون الهوية
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}