import 'package:flutter/material.dart';

class BackButtonWidget extends StatelessWidget {
  const BackButtonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          size: 22,
          color: Color(0xFF1B7C80),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}