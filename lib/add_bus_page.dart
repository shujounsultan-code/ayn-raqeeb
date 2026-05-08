import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBusPage extends StatefulWidget {
  const AddBusPage({super.key});

  @override
  State<AddBusPage> createState() => _AddBusPageState();
}

class _AddBusPageState extends State<AddBusPage> {
  final _busNumberCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _driverIdCtrl = TextEditingController(); // متحكم معرف السائق للربط مع الفايربيز
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _busNumberCtrl.dispose();
    _capacityCtrl.dispose();
    _driverIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('buses').add({
        'bus_number': int.parse(_busNumberCtrl.text.trim()),
        'capacity': int.parse(_capacityCtrl.text.trim()),
        'available_seats': int.parse(_capacityCtrl.text.trim()),
        'driver_id': _driverIdCtrl.text.trim(), // حفظ المعرف للربط التلقائي
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إضافة الحافلة بنجاح', style: TextStyle(fontFamily: 'Tajawal')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إضافة حافلة جديدة', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B7C80),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildDecoratedField(
                  controller: _busNumberCtrl,
                  label: 'رقم الحافلة',
                  hint: 'مثال: 20',
                  icon: Icons.directions_bus,
                  isNumber: true,
                ),
                const SizedBox(height: 20),
                _buildDecoratedField(
                  controller: _capacityCtrl,
                  label: 'السعة الإجمالية',
                  hint: 'عدد المقاعد',
                  icon: Icons.event_seat,
                  isNumber: true,
                ),
                const SizedBox(height: 20),
                // خانة إدخال معرف السائق للربط مع مجموعة drivers
                _buildDecoratedField(
                  controller: _driverIdCtrl,
                  label: 'معرف السائق (Driver ID)',
                  hint: 'أدخلي الـ Document ID الخاص بالسائق',
                  icon: Icons.vpn_key_rounded,
                  isNumber: false,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B7C80),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.white))
                        : const Text('حفظ البيانات', style: TextStyle(fontSize: 18, color: Colors.white, fontFamily: 'Tajawal')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecoratedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isNumber,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 5))],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
        validator: (v) => v!.isEmpty ? 'هذا الحقل مطلوب' : null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF1B7C80)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
          labelStyle: const TextStyle(fontFamily: 'Tajawal', color: Colors.grey),
        ),
      ),
    );
  }
}