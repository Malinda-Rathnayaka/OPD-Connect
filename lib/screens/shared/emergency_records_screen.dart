import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EmergencyRecordsScreen extends StatelessWidget {
  final String? doctorId;
  final bool isAdmin;

  const EmergencyRecordsScreen({
    super.key,
    this.doctorId,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final query = isAdmin
        ? FirebaseFirestore.instance.collection('emergency_records')
        : FirebaseFirestore.instance
            .collection('emergency_records')
            .where('doctorId', isEqualTo: doctorId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Emergency Records'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Unable to load emergency records: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final records = snapshot.data!.docs.toList()
            ..sort((a, b) => _recordDate(b).compareTo(_recordDate(a)));
          if (records.isEmpty) {
            return const Center(
              child: Text('No emergency records found.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _recordCard(records[index]),
          );
        },
      ),
    );
  }

  Widget _recordCard(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final patientName = data['patientName']?.toString().trim();
    final reason = data['reason']?.toString().trim() ?? 'Emergency case';
    final treatment = data['treatmentGiven']?.toString().trim() ??
        data['details']?.toString().trim() ??
        '';
    final notes = data['notes']?.toString().trim() ?? '';
    final doctor = data['doctorName']?.toString().trim() ?? '';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: const Color(0xFFDC2626),
                  child: Text(
                    (patientName?.isNotEmpty == true
                            ? patientName![0]
                            : '?')
                        .toUpperCase(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    patientName?.isNotEmpty == true
                        ? patientName!
                        : 'Unknown patient',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _formatDate(_recordDate(document)),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _detail('Emergency reason', reason),
            if (treatment.isNotEmpty) _detail('Treatment', treatment),
            if (notes.isNotEmpty) _detail('Notes', notes),
            if (doctor.isNotEmpty) _detail('Doctor', doctor),
          ],
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 13,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  DateTime _recordDate(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final value = document.data()['createdAt'] ?? document.data()['date'];
    if (value is Timestamp) return value.toDate();
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatDate(DateTime date) {
    if (date.millisecondsSinceEpoch == 0) return 'Date unavailable';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
