import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/back_button_widget.dart';

class DriversScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const DriversScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  bool isLoading = true;
  List drivers = [];

  Future<void> fetchDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/get_school_drivers.php?id=${widget.schoolId}'),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          drivers = data['drivers'];
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

  Widget _driverCard(Map driver) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Color(0xFFEAF7F8),
            child: Icon(Icons.person, color: Color(0xFF1B7C80)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  driver['driver_name']?.toString() ?? '-',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'رقم السائق: ${driver['driver_id'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'الجوال: ${driver['phone_number'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'رقم الرخصة: ${driver['license_number'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchDrivers();
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
                        'السائقين',
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
                    else if (drivers.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('لا يوجد سائقون'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: drivers.length,
                          itemBuilder: (context, index) {
                            return _driverCard(drivers[index]);
                          },
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