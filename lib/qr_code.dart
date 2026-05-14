import 'package:flutter/material.dart';
import 'qr_scanner.dart';

/// تبويب السائق: مسح رمز صعود الطالب.
class QrCodePage extends StatelessWidget {
  const QrCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xffebedf0),
        body: SafeArea(
          child: Center(
            child: Container(
              width: 430,
              constraints: const BoxConstraints(maxWidth: 430),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    size: 72,
                    color: Colors.teal.shade700,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'صعود الطلاب',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff1b7c80),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'عند صعود طالب للحافلة، اطلب منه بطاقة الرمز من المدرسة ثم امسح الرمز بالكاميرا. سيصل ولي الأمر تنبيهاً داخل التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff1b7c80),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const QrScannerPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.photo_camera, color: Colors.white),
                      label: const Text(
                        'فتح الكاميرا ومسح الرمز',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
