import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/back_button_widget.dart';

class BusAlertsScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;

  const BusAlertsScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
  });

  @override
  State<BusAlertsScreen> createState() => _BusAlertsScreenState();
}

class _BusAlertsScreenState extends State<BusAlertsScreen> {
  bool isLoading = true;
  List alerts = [];

  Future<void> fetchAlerts() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/get_bus_alerts.php?id=${widget.schoolId}'),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          alerts = data['alerts'];
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

  IconData _iconForStatus(String status) {
    if (status == 'active') return Icons.directions_bus;
    return Icons.warning_amber_rounded;
  }

  Color _colorForStatus(String status) {
    if (status == 'active') return const Color(0xFF1B7C80);
    return Colors.orange;
  }

  Widget _alertCard(Map item) {
    final status = item['status']?.toString() ?? '';
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
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFEAF7F8),
            child: Icon(
              _iconForStatus(status),
              color: _colorForStatus(status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'الباص ${item['bus_number'] ?? '-'}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['message']?.toString() ?? '-',
                  style: const TextStyle(color: Colors.black87),
                ),
                Text(
                  'المسار: ${item['route_description'] ?? '-'}',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  'المقاعد المتاحة: ${item['available_seats'] ?? '-'} من ${item['capacity'] ?? '-'}',
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
    fetchAlerts();
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
                        'تنبيهات الباصات',
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
                    else if (alerts.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('لا توجد تنبيهات'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            return _alertCard(alerts[index]);
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