import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../parent_session.dart';
import 'bus_tracking_screen.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const Color mainColor = Color(0xFF1B7C80);
  static const String _baseUrl = 'https://aynraqeeb-ai-production.up.railway.app';
  static const String _apiKey = 'aynraqeeb-secret-key-change-this';

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isTyping = false;
  String? _sessionId;

  final List<Map<String, dynamic>> _messages = [];

  String get _parentId => ParentSession.parentBusinessId ?? 'parent_123';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  double _calcDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLon = (lon2 - lon1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;

    _controller.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': _apiKey,
        },
        body: jsonEncode({
          'message': text,
          'parent_id': _parentId,
          if (_sessionId != null) 'session_id': _sessionId,
        }),
      );

      String reply = 'تعذر الحصول على رد من المساعد الذكي.';

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        reply = data['answer'] ?? 'لم أستطع فهم الرد.';
        _sessionId = data['session_id'];
      } else {
        debugPrint('AI ERROR ${response.statusCode}: ${response.body}');
        reply = 'حدث خطأ في الاتصال بالمساعد الذكي.';
      }

      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
        _isTyping = false;
      });
    } catch (e) {
      debugPrint('AI CHAT ERROR: $e');
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'تأكد من الاتصال بالإنترنت وحاول مرة أخرى.',
        });
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    super.dispose();
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back_ios, size: 24),
                  ),
                  const Spacer(),
                  const Column(
                    children: [
                      Text(
                        'المساعد الذكي',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'متاح',
                        style: TextStyle(fontSize: 13, color: mainColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: mainColor,
                    child: Icon(Icons.smart_toy, color: Colors.white, size: 28),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                DateFormat('yyyy/MM/dd').format(DateTime.now()),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _messages.isEmpty
                  ? _buildWelcome()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _messages.length + (_isTyping ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (_isTyping && i == _messages.length) {
                          return _buildTyping();
                        }
                        final msg = _messages[i];
                        return _buildBubble(msg['text'] ?? '', msg['role'] == 'user');
                      },
                    ),
            ),
            if (_messages.isEmpty) _buildQuickQuestions(),
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
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.send, color: mainColor, size: 28),
                            onPressed: _sendMessage,
                          ),
                          hintText: 'اكتب رسالتك...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _sendMessage(),
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

  Widget _buildWelcome() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'مرحبًا ${ParentSession.parentName ?? ''} 👋\n'
          'أنا مساعدك الذكي في تطبيق عين رقيب.\n'
          'يمكنني مساعدتك في متابعة الطالب، الباص، الحضور، والرسوم.',
          textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 16, height: 1.7, color: Color(0xFF333333)),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final questions = ['وين ابني الحين؟', 'متى يوصل الباص؟', 'حالة الباص؟', 'كيف أدفع الرسوم؟'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: questions.map((q) {
          return GestureDetector(
            onTap: () { _controller.text = q; _sendMessage(); },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: mainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mainColor.withValues(alpha: 0.4)),
              ),
              child: Text(q, style: const TextStyle(fontSize: 13, color: mainColor)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, double>? _extractCoordinates(String text) {
    final RegExp regExp = RegExp(r'[+-]?[0-9]+\.[0-9]+');
    final matches = regExp.allMatches(text).toList();
    if (matches.length >= 2) {
      try {
        double lat = double.parse(matches[0].group(0)!);
        double lng = double.parse(matches[1].group(0)!);
        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          return {'lat': lat, 'lng': lng};
        }
      } catch (e) { /* ignore */ }
    }
    return null;
  }

  Widget _maybeBuildMap(String text) {
    final coords = _extractCoordinates(text);
    if (coords == null) return const SizedBox.shrink();
    final position = LatLng(coords['lat']!, coords['lng']!);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusTrackingScreen())),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: FlutterMap(
            options: MapOptions(
              initialCenter: position,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.appaynraqeeb.ayn_raqeeb',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: position,
                  width: 45, height: 45,
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.directions_bus, color: mainColor, size: 26),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8, left: isUser ? 60 : 0, right: isUser ? 0 : 60),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? mainColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.right,
              style: TextStyle(fontSize: 14.5, height: 1.5, color: isUser ? Colors.white : const Color(0xFF1A1A1A))),
            if (!isUser) _maybeBuildMap(text),
          ],
        ),
      ),
    );
  }

  Widget _buildTyping() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8, right: 60),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: const Text('جاري كتابة الرد...', style: TextStyle(color: Colors.grey)),
      ),
    );
  }
}
