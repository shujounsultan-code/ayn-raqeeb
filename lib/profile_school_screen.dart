import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/back_button_widget.dart';
import 'school_info_screen.dart';
import 'drivers_screen.dart';
import 'bus_alerts_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileSchoolScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const ProfileSchoolScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<ProfileSchoolScreen> createState() => _ProfileSchoolScreenState();
}

class _ProfileSchoolScreenState extends State<ProfileSchoolScreen> {
  String buses = '0';
  String drivers = '0';
  bool isLoading = true;

  Future<void> fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/get_school_stats.php?id=${widget.schoolId}'),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          buses = data['buses'].toString();
          drivers = data['drivers'].toString();
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

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1B7C80), size: 26),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String title,
    IconData icon,
    Widget page,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 17),
              ),
            ),
            Icon(icon, color: const Color(0xFF1B7C80)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginScreen(),
          ),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: const Center(
          child: Text(
            'تسجيل الخروج',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
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
                        'حسابي',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.school,
                            size: 52,
                            color: Color(0xFF1B7C80),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            widget.schoolName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'المعرّف: ${widget.schoolId}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B7C80),
                        ),
                      )
                    else
                      Row(
                        children: [
                          _buildStatCard('السائقين', drivers, Icons.person),
                          _buildStatCard(
                            'الباصات',
                            buses,
                            Icons.directions_bus,
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            _buildItem(
                              context,
                              'معلومات المدرسة',
                              Icons.info_outline,
                              SchoolInfoScreen(
                                schoolId: widget.schoolId,
                                schoolName: widget.schoolName,
                              ),
                            ),
                            _buildItem(
                              context,
                              'السائقين',
                              Icons.people_outline,
                              DriversScreen(
                                schoolId: widget.schoolId,
                                schoolName: widget.schoolName,
                              ),
                            ),
                            _buildItem(
                              context,
                              'تنبيهات الباصات',
                              Icons.notifications_outlined,
                              BusAlertsScreen(
                                schoolId: widget.schoolId,
                                schoolName: widget.schoolName,
                              ),
                            ),
                            _buildItem(
                              context,
                              'الإعدادات',
                              Icons.settings_outlined,
                              SettingsScreen(
                                schoolId: widget.schoolId,
                                schoolName: widget.schoolName,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildLogoutButton(context),
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
