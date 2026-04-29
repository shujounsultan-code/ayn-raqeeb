import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const Color mainColor = Color(0xFF1B7C80);

  final TextEditingController _controller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  String getCurrentDate() {
    return DateFormat('yyyy/MM/dd').format(DateTime.now());
  }

  Future<void> _listen() async {
    if (!_isListening) {
      final available = await _speech.initialize();

      if (available) {
        setState(() => _isListening = true);

        _speech.listen(
          localeId: 'ar_SA',
          onResult: (result) {
            setState(() {
              _controller.text = result.recognizedWords;
              _controller.selection = TextSelection.fromPosition(
                TextPosition(offset: _controller.text.length),
              );
            });
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      await _speech.stop();
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    debugPrint(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios, size: 24),
                  const Spacer(),
                  const Column(
                    children: [
                      Text(
                        'AI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'متاح',
                        style: TextStyle(
                          fontSize: 13,
                          color: mainColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: mainColor,
                    child: Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                getCurrentDate(),
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 30),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Text(
                  'أهلًا بك في عين رقيب، كيف يمكنني\nمساعدتك اليوم؟',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.7,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: TextField(
                        controller: _controller,
                        textAlign: TextAlign.right,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: mainColor,
                              size: 28,
                            ),
                            onPressed: _sendMessage,
                          ),
                          hintText: 'اكتب رسالتك...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _listen,
                    borderRadius: BorderRadius.circular(40),
                    child: CircleAvatar(
                      radius: 31,
                      backgroundColor: _isListening ? Colors.red : mainColor,
                      child: Icon(
                        _isListening ? Icons.stop : Icons.mic,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}