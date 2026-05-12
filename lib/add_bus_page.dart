import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBusPage extends StatefulWidget {
  final String schoolId;

  const AddBusPage({
    super.key,
    required this.schoolId,
  });

  @override
  State<AddBusPage> createState() => _AddBusPageState();
}

class _AddBusPageState extends State<AddBusPage> {
  final _busNumberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('buses').add({
        'school_id': widget.schoolId,
        'bus_number': int.parse(_busNumberCtrl.text.trim()),
        'capacity': int.parse(_capacityCtrl.text.trim()),
        'available_seats': int.parse(_capacityCtrl.text.trim()), 
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إضافة الحافلة بنجاح')));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إضافة حافلة'), backgroundColor: const Color(0xFF1B7C80)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField(_busNumberCtrl, 'رقم الحافلة', Icons.directions_bus, true),
                const SizedBox(height: 20),
                _buildField(_capacityCtrl, 'السعة (عدد المقاعد)', Icons.event_seat, true),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity, height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B7C80)),
                    child: _isLoading ? const CircularProgressIndicator() : const Text('حفظ البيانات', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, bool isNum) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
    );
  }
}
