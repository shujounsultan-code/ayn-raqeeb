import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../parent_session.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  static const Color mainColor = Color(0xFF1B7C80);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _isTyping = false;

  final List<Map<String, dynamic>> _messages = [];

  String get _parentId => ParentSession.parentBusinessId ?? 'parent_123';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<String> _buildStudentContext() async {
    final studentName = ParentSession.studentNameOnParent ?? 'الطالب';
    final parentName = ParentSession.parentName ?? 'ولي الأمر';
    final busId = ParentSession.studentBusOnParent ?? 'غير محدد';

    return '''
اسم ولي الأمر: $parentName
اسم الطالب: $studentName
رقم الباص: $busId

تعليمات مهمة:
•⁠  ⁠أجب بالعربية فقط وبأسلوب واضح ومختصر.
•⁠  ⁠إذا سأل ولي الأمر عن وقت وصول الباص، قل إن الوقت المتوقع يظهر في صفحة تتبع الباص حسب آخر تحديث للموقع.
•⁠  ⁠إذا سأل عن موقع الطالب أو الباص، قل إن الموقع يمكن متابعته من صفحة تتبع الباص والخريطة المباشرة داخل التطبيق.
•⁠  ⁠إذا سأل عن الرسوم، وضح أن الدفع يكون من صفحة الرسوم داخل التطبيق.
•⁠  ⁠إذا سأل عن الحضور، وضح أنه يمكن معرفة الحالة من صفحة الحضور.
•⁠  ⁠لا تذكر أسماء أو أرقام هواتف غير موجودة في بيانات الجلسة.
•⁠  ⁠لا تخترع وقت وصول أو موقع غير موجود.
''';
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
      final context = await _buildStudentContext();

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/v1/ai/chat'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': 'aynraqeeb-secret-key-change-this',
        },
        body: jsonEncode({
          'message': '''
$context

سؤال ولي الأمر:
$text
''',
          'user_id': _parentId,
        }),
      );

      String reply = 'تعذر الحصول على رد من المساعد الذكي.';

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        reply = data['answer'] ??
            data['response'] ??
            data['message'] ??
            data['reply'] ??
            'لم أستطع فهم الرد.';
      } else {
        print(response.statusCode);
        print(response.body);
        reply = 'حدث خطأ في الاتصال بالمساعد الذكي.';
      }

      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'assistant', 'text': reply});
        _isTyping = false;
      });
    } catch (e) {
      print('AI CHAT ERROR: $e');

      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': 'تأكدي أن سيرفر الذكاء الاصطناعي شغال ثم حاولي مرة أخرى.',
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
                        return _buildBubble(
                          msg['text'] ?? '',
                          msg['role'] == 'user',
                        );
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
          style: const TextStyle(
            fontSize: 16,
            height: 1.7,
            color: Color(0xFF333333),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final questions = [
      'وين ابني الحين؟',
      'متى يوصل الباص؟',
      'حالة الباص؟',
      'كيف أدفع الرسوم؟',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: questions.map((q) {
          return GestureDetector(
            onTap: () {
              _controller.text = q;
              _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: mainColor.withOpacity(0.4)),
              ),
              child: Text(
                q,
                style: const TextStyle(fontSize: 13, color: mainColor),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? mainColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          text,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 14.5,
            height: 1.5,
            color: isUser ? Colors.white : const Color(0xFF1A1A1A),
          ),
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'جاري كتابة الرد...',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}