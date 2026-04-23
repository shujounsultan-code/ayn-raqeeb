import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'widgets/back_button_widget.dart';

class RecordsScreen extends StatefulWidget {
  final String schoolId;

  const RecordsScreen({super.key, required this.schoolId});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  bool isLoading = true;
  List records = [];

  Future<void> fetchRecords() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2/get_school_records.php?id=${widget.schoolId}'),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          records = data['records'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    fetchRecords();
  }

  Widget recordCard(Map item) {
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
          const Icon(Icons.history, color: Color(0xFF1B7C80)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item['description'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  item['time'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
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
                        'سجلاتي',
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
                    else if (records.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('لا توجد سجلات'),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) {
                            return recordCard(records[index]);
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