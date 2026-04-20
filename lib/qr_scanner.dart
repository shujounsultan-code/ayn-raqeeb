import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({Key? key}) : super(key: key);

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  CameraController? _controller;
  bool _cameraAvailable = true;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
      _controller = CameraController(camera, ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {});
    } catch (e) {
      setState(() {
        _cameraAvailable = false;
        _showFallback = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _simulateCapture() {
    // Simulate capture action
    Navigator.pushReplacementNamed(context, '/qr_code', arguments: '');
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xffebedf0),
        body: Center(
          child: Container(
            width: 430,
            constraints: BoxConstraints(maxWidth: 430),
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 25,
                ),
              ],
            ),
            child: Stack(
              children: [
                // زر رجوع صغير في الأعلى
                Positioned(
                  top: 24,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.black),
                    ),
                  ),
                ),
                if (_cameraAvailable && _controller != null && _controller!.value.isInitialized)
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CameraPreview(_controller!),
                  ),
                if (_showFallback)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'تعذر الوصول إلى الكاميرا. يمكنك استخدام المحاكاة بدلاً من ذلك.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _simulateCapture,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: CircleBorder(),
                            padding: EdgeInsets.all(20),
                          ),
                          child: Text('محاكاة التقاط صورة', style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  ),
                // Scan frame
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 4, color: Color(0xff1b7c80)),
                                left: BorderSide(width: 4, color: Color(0xff1b7c80)),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(width: 4, color: Color(0xff1b7c80)),
                                right: BorderSide(width: 4, color: Color(0xff1b7c80)),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(width: 4, color: Color(0xff1b7c80)),
                                left: BorderSide(width: 4, color: Color(0xff1b7c80)),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(width: 4, color: Color(0xff1b7c80)),
                                right: BorderSide(width: 4, color: Color(0xff1b7c80)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Capture button
                if (_cameraAvailable && _controller != null && _controller!.value.isInitialized)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          // Implement image capture and navigation
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
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
    );
  }
}
