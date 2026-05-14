import 'package:flutter/material.dart';
import '../main.dart';
import '../parent_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParentLoginScreen extends StatefulWidget {
  const ParentLoginScreen({super.key});

  @override
  State<ParentLoginScreen> createState() => _ParentLoginScreenState();
}

class _ParentLoginScreenState extends State<ParentLoginScreen> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    idController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final parentId = idController.text.trim();
    final password = passwordController.text.trim();

    if (parentId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال المعرف وكلمة المرور')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('parents')
          .where('parent_id', isEqualTo: parentId)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('المعرّف أو كلمة المرور غير صحيحة')),
        );
        return;
      }

      ParentSession.setFromParentDocument(snap.docs.first);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ParentNavigation(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F4F7),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logobg.png',
                    width: 170,
                    height: 150,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'تسجيل دخول ولي الأمر',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B7C80),
                    ),
                  ),
                  const SizedBox(height: 35),

                  TextField(
                    controller: idController,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'المعرّف',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  TextField(
                    controller: passwordController,
                    obscureText: _obscurePassword,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B7C80),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'دخول',
                              style: TextStyle(fontSize: 22, color: Colors.white),
                            ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'ليس لديك حساب؟ سجل الآن',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
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
