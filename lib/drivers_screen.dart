import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/back_button_widget.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _busNumberController = TextEditingController();
  String? generatedId;
  String? generatedPassword;
  bool isAdding = false;

  Future<void> fetchDrivers() async {
    setState(() { isLoading = true; });
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('drivers')
          .where('school_id', isEqualTo: widget.schoolId)
          .get();
      setState(() {
        drivers = snapshot.docs.map((doc) => doc.data()).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() { isLoading = false; });
    }
  }

  String _generateDriverId() {
    final rand = Random();
    final digits = List.generate(7, (_) => rand.nextInt(10)).join();
    return 'D$digits';
  }

  String _generatePassword() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(8, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _addDriver(BuildContext context) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final busNumber = _busNumberController.text.trim();
    if (name.isEmpty || phone.isEmpty || busNumber.isEmpty) return;
    setState(() { isAdding = true; });
    final driverId = _generateDriverId();
    final password = _generatePassword();
    try {
      await FirebaseFirestore.instance.collection('drivers').add({
        'driver_id': driverId,
        'driver_name': name,
        'phone_number': phone,
        'bus_number': busNumber,
        'password': password,
        'school_id': widget.schoolId,
      });
      setState(() {
        generatedId = driverId;
        generatedPassword = password;
      });
      _nameController.clear();
      _phoneController.clear();
      _busNumberController.clear();
      await fetchDrivers();
      Navigator.of(context).pop();
      Future.delayed(Duration.zero, () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'بيانات حساب السائق',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('المعرف: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      Text(driverId, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text('كلمة السر: ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      Text(password, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'يرجى تسليم هذه البيانات للسائق.',
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                    textAlign: TextAlign.right,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1B7C80),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('تم', style: TextStyle(color: Colors.white, fontSize: 17)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      });
    } catch (e) {
      // handle error
    }
    setState(() { isAdding = false; });
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
                  'رقم الباص: ${driver['bus_number'] ?? '-'}',
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
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'السائقين (${drivers.length})',
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                                content: StatefulBuilder(
                                  builder: (context, setStateDialog) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'إضافة سائق جديد',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                          textAlign: TextAlign.right,
                                        ),
                                        const SizedBox(height: 24),
                                        TextField(
                                          controller: _nameController,
                                          decoration: const InputDecoration(hintText: 'اسم السائق'),
                                          textAlign: TextAlign.right,
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _phoneController,
                                          decoration: const InputDecoration(hintText: 'رقم الجوال'),
                                          keyboardType: TextInputType.phone,
                                          textAlign: TextAlign.right,
                                        ),
                                        const SizedBox(height: 16),
                                        TextField(
                                          controller: _busNumberController,
                                          decoration: const InputDecoration(hintText: 'رقم الباص'),
                                          keyboardType: TextInputType.text,
                                          textAlign: TextAlign.right,
                                        ),
                                        const SizedBox(height: 32),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: OutlinedButton(
                                                onPressed: isAdding ? null : () => Navigator.of(context).pop(),
                                                style: OutlinedButton.styleFrom(
                                                  side: const BorderSide(color: Color(0xFF1B7C80)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                child: const Text('إلغاء', style: TextStyle(color: Color(0xFF1B7C80), fontSize: 17)),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: isAdding ? null : () => _addDriver(context),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1B7C80),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                                ),
                                                child: isAdding
                                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                    : const Text('حفظ', style: TextStyle(color: Colors.white, fontSize: 17)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B7C80),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('إضافة سائق جديد', style: TextStyle(color: Colors.white)),
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