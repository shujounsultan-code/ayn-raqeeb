import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';
import 'main.dart';
import 'widgets/back_button_widget.dart';
import 'home_screen.dart';
import 'main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class DriverLoginScreen extends StatefulWidget {
  const DriverLoginScreen({super.key});

  @override
  State<DriverLoginScreen> createState() => _DriverLoginScreenState();
}

class _DriverLoginScreenState extends State<DriverLoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 Future<void> _login() async {
    // 1. إظهار مؤشر التحميل
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. البحث في جدول users عن تطابق المعرف وكلمة المرور
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _idController.text.trim())
          .where('password', isEqualTo: _passwordController.text.trim())
          .get();

      // 3. التحقق من وجود المستخدم
      if (result.docs.isNotEmpty) {
        var userData = result.docs.first.data() as Map<String, dynamic>;
        
        // 4. التأكد أن "الدور" هو سائق (driver)
        if (userData['role'] == 'driver') {
          // إذا كان سائق، ننتقل للوحة التحكم
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
          );
        } else {
          // إذا وجدنا الحساب لكنه ليس سائقاً (مثلاً ولي أمر)
          _showErrorSnackBar('هذا الحساب غير مسجل كسائق');
        }
      } else {
        // إذا لم نجد أي تطابق للبيانات
        _showErrorSnackBar('المعرف أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      // في حال حدث خطأ في الاتصال
      _showErrorSnackBar('حدث خطأ في الاتصال: $e');
    } finally {
      // 5. إيقاف مؤشر التحميل
      setState(() {
        _isLoading = false;
      });
    }
  }

  // دالة مساعدة لإظهار رسائل الخطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F7),
      body: Stack(
        children: [
          // زر الرجوع في الأعلى
          BackButtonWidget(),
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
                        width: 160,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'تسجيل دخول السائق',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B7C80),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _idController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'المعرّف',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'كلمة المرور',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1B7C80),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'دخول',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'ليس لديك حساب؟ سجل الآن',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
