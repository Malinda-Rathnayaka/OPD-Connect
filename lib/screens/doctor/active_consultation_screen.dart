import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';

class ActiveConsultationScreen extends StatefulWidget {
  final String sessionId;

  const ActiveConsultationScreen({super.key, required this.sessionId});

  @override
  State<ActiveConsultationScreen> createState() => _ActiveConsultationScreenState();
}

class _ActiveConsultationScreenState extends State<ActiveConsultationScreen> {
  final DoctorService _service = DoctorService();
  
  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Consultation', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('ROOM 04 • DR. KAMAL PERERA', style: TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .doc(widget.sessionId)
            .collection('queue')
            .where('status', isEqualTo: 'IN_CONSULTATION')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No patient currently in consultation.'));
          }

          var activeDoc = snapshot.data!.docs.first;
          var patientData = activeDoc.data() as Map<String, dynamic>;
          String queueDocId = activeDoc.id;
          String patientId = patientData['patientId'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Details Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2563EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(patientData['patientName'] ?? 'N/A', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('NIC: ${patientData['nic'] ?? 'N/A'} • Phone: ${patientData['phone'] ?? 'N/A'} • Token ${patientData['tokenNo']}', 
                           style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Patient History Check
                FutureBuilder<List<dynamic>>(
                  future: _service.fetchPatientHistory(patientId),
                  builder: (context, historySnapshot) {
                    if (historySnapshot.hasData && historySnapshot.data!.isNotEmpty) {
                      final records = historySnapshot.data!.reversed.toList();
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history, color: Color(0xFF2563EB), size: 18),
                                const SizedBox(width: 8),
                                const Text('Previous Treatment History', style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 16),
                            ...records.map(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${record['date'] ?? 'Unknown date'} • ${record['type'] ?? 'TREATMENT'}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                    Text('Diagnosis: ${record['diagnosis'] ?? 'Not recorded'}', style: const TextStyle(fontSize: 13)),
                                    Text('Treatment: ${record['prescription'] ?? 'Not recorded'}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                                    if ((record['advice'] ?? '').toString().isNotEmpty)
                                      Text('Notes: ${record['advice']}', style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
                      child: const Text('New Patient (No previous medical history recorded)', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 1. Diagnosis Input
                const Text('Diagnosis / Disease', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _diagnosisController,
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  decoration: InputDecoration(
                    hintText: 'e.g. Acute Pharyngitis',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Prescription Input
                const Text('Prescription (Medicines)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _prescriptionController,
                  maxLines: 2,
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  decoration: InputDecoration(
                    hintText: 'e.g. Paracetamol 500mg, Amoxicillin 500mg',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Advice Input
                const Text('Special Advice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _adviceController,
                  scrollPadding: const EdgeInsets.only(bottom: 140),
                  decoration: InputDecoration(
                    hintText: 'e.g. Rest and hydration recommended',
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                    ),
                    onPressed: _isSaving ? null : () async {
                      if (_diagnosisController.text.isEmpty || _prescriptionController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Diagnosis and Prescription details')));
                        return;
                      }

                      setState(() => _isSaving = true);
                      try {
                        await _service.submitAndCallNext(
                          sessionId: widget.sessionId,
                          queueDocId: queueDocId,
                          patientId: patientId,
                          patientName: patientData['patientName']?.toString() ?? 'Unknown Patient',
                          tokenNo: patientData['tokenNo']?.toString() ?? '',
                          diagnosis: _diagnosisController.text,
                          prescription: _prescriptionController.text,
                          advice: _adviceController.text,
                        );
                        _diagnosisController.clear();
                        _prescriptionController.clear();
                        _adviceController.clear();
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Treatment saved and next patient called.')));
                      } catch (error) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save treatment: $error')));
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Complete & Call Next Patient', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
