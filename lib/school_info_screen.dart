import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/back_button_widget.dart';

class SchoolInfoScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const SchoolInfoScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<SchoolInfoScreen> createState() => _SchoolInfoScreenState();
}

class _SchoolInfoScreenState extends State<SchoolInfoScreen> {
  bool isLoading = true;
  String address = '';
  String phone = '';
  String email = '';
  String latitude = '';
  String longitude = '';

  Future<void> fetchSchoolInfo() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/get_school_info.php?id=${widget.schoolId}'),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          address = data['address']?.toString() ?? '';
          phone = data['phone_number']?.toString() ?? '';
          email = data['email']?.toString() ?? '';
          latitude = data['latitude']?.toString() ?? '';
          longitude = data['longitude']?.toString() ?? '';
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _item(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1B7C80)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchSchoolInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'معلومات المدرسة',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF1B7C80),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              _item('اسم المدرسة', widget.schoolName, Icons.school),
                              _item('المعرّف', widget.schoolId, Icons.badge_outlined),
                              _item('العنوان', address, Icons.location_on_outlined),
                              _item('الجوال', phone, Icons.phone_outlined),
                              _item('البريد', email, Icons.email_outlined),
                              _item('خط العرض', latitude, Icons.map_outlined),
                              _item('خط الطول', longitude, Icons.map_outlined),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const BackButtonWidget(),
          ],
        ),
      ),
    );
  }
}