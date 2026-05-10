import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BusDetailsPage extends StatelessWidget {
  final Map<String, dynamic> busData;
  final String busId;

  const BusDetailsPage({super.key, required this.busData, required this.busId});

  @override
  Widget build(BuildContext context) {
    final String busNumber = busData['bus_number'].toString();
    final String driverId = busData['driver_id'] ?? ''; 

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          title: Text('تفاصيل حافلة رقم $busNumber', 
            style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF1B7C80),
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBusHeader(),
              
              _buildSectionTitle('بيانات السائق', Icons.person_pin_rounded),
              _buildDriverSection(driverId),

              _buildSectionTitle('الطالبات المسجلات', Icons.groups_rounded),
              _buildStudentsList(busNumber),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverSection(String driverId) {
    if (driverId.isEmpty) {
      return _buildInfoCard('لم يتم ربط معرف السائق في قاعدة البيانات لهذا الباص');
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator()));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildInfoCard('لم يتم العثور على بيانات سائق بهذا المعرف في الفايربيز');
        }

        var driverData = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.person, 'اسم السائق:', driverData['driver_name'] ?? 'غير مسجل'),
              const Divider(height: 20),
              _buildInfoRow(Icons.phone_android, 'رقم التواصل:', driverData['phone_number'] ?? 'غير متوفر'),
              const Divider(height: 20),
_buildInfoRow(Icons.badge_outlined, 'اسم السائق:', driverData['driver_name'] ?? 'غير مسجل'),            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentsList(String busNumber) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('students')
          .where('bus_id', isEqualTo: busNumber)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text('لا توجد طالبات في هذا الباص حالياً', style: TextStyle(fontFamily: 'Tajawal', color: Colors.grey))),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var student = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF0F7F7), child: Icon(Icons.person, color: Color(0xFF1B7C80))),
                title: Text(student['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                subtitle: Text('الصف: ${student['grade']}', style: const TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBusHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B7C80),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('السعة', busData['capacity']?.toString() ?? '0'),
          _buildStatItem('المتاحة', busData['available_seats']?.toString() ?? '0'),
          const Icon(Icons.directions_bus, size: 50, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 25, 16, 12),
      child: Row(
        children: [Icon(icon, color: const Color(0xFF1B7C80)), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'))],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B7C80)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: Colors.grey, fontFamily: 'Tajawal')),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Tajawal')),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70, fontFamily: 'Tajawal')),
      ],
    );
  }

  Widget _buildInfoCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
      child: Text(message, style: const TextStyle(fontFamily: 'Tajawal', color: Colors.black54)),
    );
  }
}