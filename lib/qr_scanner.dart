import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'student_boarding_service.dart';

/// مسح رمز QR الطالب (صعود الحافلة) من كاميرا السائق.
class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleCode(String? raw) async {
    if (raw == null || raw.isEmpty || _busy) return;
    setState(() => _busy = true);
    await _controller.stop();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    try {
      final result = await recordStudentBoardingFromScan(raw);
      if (!mounted) return;

      if (result == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم تسجيل صعود الطالب وإرسال تنبيه لولي الأمر'),
          ),
        );
        nav.pop();
        return;
      }
      if (result == 'ok_no_parent') {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'تم تسجيل الصعود. لا يوجد ولي أمر مرتبط لإرسال تنبيه.',
            ),
          ),
        );
        nav.pop();
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: Colors.red.shade800,
        ),
      );
      setState(() => _busy = false);
      await _controller.start();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
      setState(() => _busy = false);
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: const Text('مسح رمز الطالب'),
          actions: [
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, state, child) {
                  final torch = state.torchState == TorchState.on;
                  return Icon(torch ? Icons.flash_on : Icons.flash_off);
                },
              ),
              onPressed: () => _controller.toggleTorch(),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final barcodes = capture.barcodes;
                if (barcodes.isEmpty) return;
                final raw = barcodes.first.rawValue;
                _handleCode(raw);
              },
            ),
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xff1b7c80), width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_busy)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Text(
                'وجّه الكاميرا نحو رمز الطالب المعروض في تطبيق المدرسة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
