import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../student_boarding_token.dart';

/// بطاقة رمز QR لصعود الطالب (يُطبع أو يُعرض على الشاشة).
class StudentBoardingQrCard extends StatelessWidget {
  const StudentBoardingQrCard({
    super.key,
    required this.schoolId,
    required this.studentDocId,
    this.studentDisplayCode,
  });

  final String schoolId;
  final String studentDocId;
  final String? studentDisplayCode;

  @override
  Widget build(BuildContext context) {
    if (schoolId.isEmpty || studentDocId.isEmpty) {
      return const SizedBox.shrink();
    }
    final payload = StudentBoardingToken.encode(
      schoolId: schoolId,
      studentDocId: studentDocId,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E4EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'رمز صعود الحافلة (QR)',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B7C80),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            studentDisplayCode != null && studentDisplayCode!.isNotEmpty
                ? 'معرف الطالب: $studentDisplayCode — يُمسح من قبل السائق عند الصعود'
                : 'يُمسح من قبل السائق عند صعود الطالب للحافلة',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: QrImageView(
                data: payload,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
