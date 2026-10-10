import 'package:flutter/material.dart';
import '../../services/doctor_service.dart';

class EmergencyTreatmentScreen extends StatefulWidget {
  final String? sessionId;
  final String? queueDocId;

  const EmergencyTreatmentScreen({
    super.key,
    this.sessionId,
    this.queueDocId,
  });

  @override
  State<EmergencyTreatmentScreen> createState() => _EmergencyTreatmentScreenState();
}

class _EmergencyTreatmentScreenState extends State<EmergencyTreatmentScreen> {
  final DoctorService _service = DoctorService();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _reasonController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _reasonController.dispose();
    _treatmentController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveEmergencyRecord() async {
    if (_nameController.text.isEmpty || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient Name and Emergency Reason are required!')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (widget.sessionId != null && widget.queueDocId != null) {
        await _service.skipCurrentPatient(
          sessionId: widget.sessionId!,
          queueDocId: widget.queueDocId!,
          reason: _reasonController.text.trim(),
          details: '${_treatmentController.text.trim()}\n${_notesController.text.trim()}',
        );
      } else {
        await _service.logEmergencyTreatment(
          patientName: _nameController.text.trim(),
          nicOrPhone: _nicController.text.trim(),
          reason: _reasonController.text.trim(),
          treatmentGiven: _treatmentController.text.trim(),
          notes: _notesController.text.trim(),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Emergency Case logged and linked to patient history!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log emergency: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String dateStr = "${now.year}-${now.month}-${now.day}";
    String timeStr = "${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFDC2626),
        title: const Text('Log Emergency Case', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Date/Time Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                  Text('Time: $timeStr', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B))),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildField('Patient Name', 'e.g. Sunil Shantha', _nameController),
            _buildField('NIC / Phone Number', 'e.g. 199012345678 or 0712345678', _nicController),
            _buildField('Emergency Reason / Symptom', 'e.g. Severe Chest Pain / Asthma Attack', _reasonController, maxLines: 2),
            _buildField('Treatment / Injection Given', 'e.g. Nebulized / Hydrocortisone IV', _treatmentController, maxLines: 2),
            _buildField('Additional Clinical Notes', 'e.g. Sent to ICU Ward 02', _notesController, maxLines: 2),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveEmergencyRecord,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Update Patient History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            maxLines: maxLines,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            decoration: InputDecoration(
              hintText: hint,
              fillColor: Colors.white,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
        ],
      ),
    );
  }
}
