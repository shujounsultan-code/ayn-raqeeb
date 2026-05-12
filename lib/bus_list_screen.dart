import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// الاستيرادات التي طلبتها
import 'widgets/back_button_widget.dart';

class BusListScreen extends StatelessWidget {
  final String schoolId;

  const BusListScreen({
    Key? key,
    required this.schoolId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1b7c80),
          elevation: 0,
          centerTitle: true,
          leading: const BackButtonWidget(),
          title: const Text(
            'قائمة الباصات المدرسية',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('buses')
              .where('school_id', isEqualTo: schoolId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF1b7c80)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('لا توجد باصات مسجلة حالياً'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var busDoc = snapshot.data!.docs[index];
                var busData = busDoc.data() as Map<String, dynamic>;

                return _buildBusItem(context, busData);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildBusItem(BuildContext context, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusDetailsScreen(
                schoolId: schoolId,
                busNumber: data['bus_number'] ?? '0',
                driverName: data['driver_name'] ?? 'غير مسجل',
                phone: data['phone_number'] ?? '',
              ),
            ),
          );
        },
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFF1b7c80).withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.directions_bus_rounded, color: Color(0xFF1b7c80), size: 30),
        ),
        title: Text(
          'باص رقم ${data['bus_number']}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('السائق: ${data['driver_name']}'),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }
}

// --- شاشة تفاصيل الباص (السائق + الطالبات) ---
class BusDetailsScreen extends StatelessWidget {
  final String schoolId;
  final String busNumber;
  final String driverName;
  final String phone;

  const BusDetailsScreen({
    Key? key,
    required this.schoolId,
    required this.busNumber,
    required this.driverName,
    required this.phone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int? busNumberAsInt = int.tryParse(busNumber);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1b7c80),
          title: Text('تفاصيل باص $busNumber'),
          centerTitle: true,
        ),
        body: Column(
          children: [
            // بطاقة معلومات السائق
            _buildDriverInfoCard(),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'الطالبات المسجلات في هذا الباص',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1b7c80)),
                ),
              ),
            ),

            // قائمة الطالبات
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('students')
                    .where('school_id', isEqualTo: schoolId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final wantedBus = (busNumberAsInt ?? busNumber).toString().trim();
                  final docs = snapshot.data!.docs.where((d) {
                    final student = d.data() as Map<String, dynamic>;
                    final sBus = (student['bus'] ?? '').toString().trim();
                    return sBus == wantedBus;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('لا توجد طالبات مضافات لهذا الباص بعد'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var student = docs[index].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFF0F7F7),
                            child: Icon(Icons.person, color: Color(0xFF1b7c80)),
                          ),
                          title: Text(student['name'] ?? 'بدون اسم', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('الصف: ${student['grade'] ?? 'غير محدد'}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1b7c80), Color(0xFF2a9d9d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('قائد المركبة', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    Text(driverName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                icon: const Icon(Icons.phone_in_talk, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.white12),
              )
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDriverStat(Icons.numbers, 'رقم الباص', busNumber),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDriverStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
