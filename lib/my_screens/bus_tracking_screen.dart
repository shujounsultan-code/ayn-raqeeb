import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../parent_session.dart';
import 'parent_student_scope.dart';

/// تتبع موقع حافلة الطالب من مجموعة `bus_locations` (نفس معرف المستند المستخدم في لوحة السائق).
class BusTrackingScreen extends StatefulWidget {
  const BusTrackingScreen({super.key});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  static const Color teal = Color(0xFF1B7C80);
  static const Color darkBlue = Color(0xFF0B4C75);
  static const LatLng _fallbackCenter = LatLng(21.4858, 39.1925);

  final MapController _mapController = MapController();
  String? _selectedTrackDocId;

  String _effectiveTrackDocId(
    List<DocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    if (docs.isEmpty) return '';
    final sel = _selectedTrackDocId;
    if (sel != null && docs.any((d) => d.id == sel)) return sel;
    return docs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('التنبيهات')),
                      );
                    },
                    child: const Icon(
                      Icons.notifications_none,
                      size: 34,
                      color: Colors.black,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logobg.png',
                        width: 95,
                        height: 70,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, __) =>
                            const Icon(Icons.school, size: 48, color: teal),
                      ),
                      Transform.translate(
                        offset: const Offset(0, -10),
                        child: const Text(
                          'عين رقيب',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تتبع حافلة طفلك',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: darkBlue,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
                stream: parentLinkedStudentsStream(),
                builder: (context, listSnap) {
                  if (listSnap.connectionState == ConnectionState.waiting &&
                      !listSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (listSnap.hasError) {
                    return Center(
                      child: Text('تعذّر التحميل: ${listSnap.error}'),
                    );
                  }
                  final docs = listSnap.data ?? [];
                  if (docs.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'لا يوجد طالب مرتبط بحسابك. تواصل مع المدرسة لربط الطالب.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    );
                  }

                  final effId = _effectiveTrackDocId(docs);
                  final st = docs.firstWhere((d) => d.id == effId);
                  if (!st.exists || st.data() == null) {
                    return const Center(child: Text('بيانات الطالب غير متاحة'));
                  }
                  final data = st.data()!;
                  final name = data['name']?.toString() ?? '';
                  final bus = data['bus']?.toString().trim() ?? '';
                  final schoolId = (data['school_id'] ??
                              ParentSession.schoolIdFromParent)
                          ?.toString()
                          .trim() ??
                      '';

                  if (bus.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'لا يوجد رقم باص مسجّل لهذا الطالب.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  final busLocDocId =
                      schoolId.isNotEmpty ? '${schoolId}_$bus' : bus;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (docs.length > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DropdownButtonFormField<String>(
                            value: effId,
                            decoration: const InputDecoration(
                              labelText: 'تتبع باص الطالب',
                              border: OutlineInputBorder(),
                            ),
                            items: docs.map((d) {
                              final n =
                                  d.data()?['name']?.toString() ?? d.id;
                              return DropdownMenuItem(
                                value: d.id,
                                child: Text(n, textAlign: TextAlign.right),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedTrackDocId = v);
                              }
                            },
                          ),
                        ),
                      if (docs.length > 1) const SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('bus_locations')
                              .doc(busLocDocId)
                              .snapshots(),
                          builder: (context, locSnap) {
                            LatLng center = _fallbackCenter;
                            double zoom = 13;
                            LatLng? busPoint;
                            double? accuracy;

                            if (locSnap.hasData &&
                                locSnap.data!.exists &&
                                locSnap.data!.data() != null) {
                              final ld = locSnap.data!.data()!;
                              if (ld['lat'] is num && ld['lng'] is num) {
                                busPoint = LatLng(
                                  (ld['lat'] as num).toDouble(),
                                  (ld['lng'] as num).toDouble(),
                                );
                                center = busPoint;
                                accuracy =
                                    (ld['accuracy'] as num?)?.toDouble() ?? 45;
                                zoom = 14.5;
                              }
                            }

                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (busPoint != null && mounted) {
                                _mapController.move(busPoint, zoom);
                              }
                            });

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: schoolId.isNotEmpty
                                      ? StreamBuilder<
                                          DocumentSnapshot<
                                              Map<String, dynamic>>>(
                                          stream: FirebaseFirestore.instance
                                              .collection('schools')
                                              .doc(schoolId)
                                              .snapshots(),
                                          builder: (context, sch) {
                                            final sname = sch.data
                                                    ?.data()?['school_name']
                                                    ?.toString() ??
                                                '';
                                            return _infoCard(
                                              name: name,
                                              bus: bus,
                                              busLocDocId: busLocDocId,
                                              busPoint: busPoint,
                                              schoolLine: sname.isNotEmpty
                                                  ? 'المدرسة: $sname'
                                                  : null,
                                            );
                                          },
                                        )
                                      : _infoCard(
                                          name: name,
                                          bus: bus,
                                          busLocDocId: busLocDocId,
                                          busPoint: busPoint,
                                          schoolLine: null,
                                        ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 0, 16, 16),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: FlutterMap(
                                        mapController: _mapController,
                                        options: MapOptions(
                                          initialCenter: center,
                                          initialZoom: zoom,
                                          interactionOptions:
                                              const InteractionOptions(
                                            enableScrollWheel: false,
                                            enableMultiFingerGestureRace:
                                                false,
                                          ),
                                        ),
                                        children: [
                                          TileLayer(
                                            urlTemplate:
                                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                            subdomains: const ['a', 'b', 'c'],
                                            userAgentPackageName:
                                                'com.example.ayn_raqeeb_app',
                                          ),
                                          if (busPoint != null &&
                                              accuracy != null)
                                            CircleLayer(
                                              circles: [
                                                CircleMarker(
                                                  point: busPoint,
                                                  color: const Color(0xFFdc2626)
                                                      .withOpacity(0.12),
                                                  borderStrokeWidth: 1,
                                                  borderColor: const Color(
                                                      0xFFdc2626),
                                                  radius: accuracy / 2,
                                                ),
                                              ],
                                            ),
                                          if (busPoint != null)
                                            MarkerLayer(
                                              markers: [
                                                Marker(
                                                  width: 44,
                                                  height: 44,
                                                  point: busPoint,
                                                  child: const Icon(
                                                    Icons.directions_bus,
                                                    color: Color(0xFFdc2626),
                                                    size: 40,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String name,
    required String bus,
    required String busLocDocId,
    required LatLng? busPoint,
    String? schoolLine,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (schoolLine != null) ...[
            Text(
              schoolLine,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: teal,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            name.isNotEmpty ? 'الطالب: $name' : 'تتبع الباص',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الباص: $bus — مرجع الموقع: $busLocDocId',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.right,
          ),
          if (busPoint == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'بانتظار إرسال موقع الحافلة من جهاز السائق…',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade800,
                ),
                textAlign: TextAlign.right,
              ),
            ),
        ],
      ),
    );
  }
}
