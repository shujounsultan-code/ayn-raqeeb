import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsPage extends StatelessWidget {
  final String parentId; 
  const NotificationsPage({Key? key, required this.parentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('التنبيهات', style: TextStyle(color: Colors.white)), backgroundColor: const Color(0xFF1B7C80)),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('notifications').where('parent_id', isEqualTo: parentId).orderBy('time', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                var note = snapshot.data!.docs[index];
                return ListTile(
                  leading: const Icon(Icons.notifications_active, color: Color(0xFF1B7C80)),
                  title: Text(note['text']),
                  subtitle: Text(note['time'] != null ? (note['time'] as Timestamp).toDate().toString() : ''),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
