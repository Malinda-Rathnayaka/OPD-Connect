import 'dart:ui';
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
  State<EmergencyTreatmentScreen> createState() =>
      _EmergencyTreatmentScreenState();
}

class _EmergencyTreatmentScreenState extends State<EmergencyTreatmentScreen> {
  final DoctorService _service = DoctorService();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _reasonController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  String? _focusedField;

  // ---- Theme tokens (aligned with the app) ----
  static const Color _bgTop = Color(0xFFFFF1F2);
  static const Color _bgMid = Color(0xFFF8FAFC);
  static const Color _bgBottom = Color(0xFFFFFFFF);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _dangerDark = Color(0xFF991B1B);
  static const Color _dangerLight = Color(0xFFEF4444);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _fieldFill = Color(0xFFF8FAFC);

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
        const SnackBar(
          content: Text('Patient Name and Emergency Reason are required!'),
        ),
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
          details:
              '${_treatmentController.text.trim()}\n${_notesController.text.trim()}',
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
          const SnackBar(
            content: Text(
              'Emergency Case logged and linked to patient history!',
            ),
          ),
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
      backgroundColor: _bgMid,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Material(
            color: _surface,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: _danger.withOpacity(0.25),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: _danger,
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [_dangerDark, _danger],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(rect),
              child: const Text(
                'Log Emergency Case',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'IMMEDIATE ATTENTION REQUIRED',
              style: TextStyle(
                color: _danger,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Soft light background gradient (red-tinted for emergency context)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_bgTop, _bgMid, _bgBottom],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. Soft red + blue radial glows
          Positioned(
            top: -140,
            left: -120,
            child: _glow(
                color: const Color(0xFFFCA5A5).withOpacity(0.45), radius: 260),
          ),
          Positioned(
            top: 100,
            right: -160,
            child: _glow(
                color: const Color(0xFFFECACA).withOpacity(0.55), radius: 240),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: _glow(
                color: const Color(0xFFFEE2E2).withOpacity(0.65), radius: 280),
          ),

          // 3. Content
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency banner with date/time
                _buildEmergencyBanner(dateStr, timeStr),
                const SizedBox(height: 22),

                // Section header
                _sectionHeader('Patient Information'),
                const SizedBox(height: 14),

                _buildField(
                  id: 'name',
                  label: 'Patient Name',
                  hint: 'e.g. Sunil Shantha',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 14),
                _buildField(
                  id: 'nic',
                  label: 'NIC / Phone Number',
                  hint: 'e.g. 199012345678 or 0712345678',
                  controller: _nicController,
                  icon: Icons.badge_outlined,
                ),

                const SizedBox(height: 22),
                _sectionHeader('Emergency Details'),
                const SizedBox(height: 14),

                _buildField(
                  id: 'reason',
                  label: 'Emergency Reason / Symptom',
                  hint: 'e.g. Severe Chest Pain / Asthma Attack',
                  controller: _reasonController,
                  icon: Icons.warning_amber_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _buildField(
                  id: 'treatment',
                  label: 'Treatment / Injection Given',
                  hint: 'e.g. Nebulized / Hydrocortisone IV',
                  controller: _treatmentController,
                  icon: Icons.medication_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _buildField(
                  id: 'notes',
                  label: 'Additional Clinical Notes',
                  hint: 'e.g. Sent to ICU Ward 02',
                  controller: _notesController,
                  icon: Icons.sticky_note_2_outlined,
                  maxLines: 2,
                ),

                const SizedBox(height: 28),

                // Save button with red glow
                SizedBox(
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: _danger.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _danger,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                _danger.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed:
                              _isSaving ? null : _saveEmergencyRecord,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.save_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Save & Update Patient History',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Emergency banner (gradient red with date/time chips)
  // ─────────────────────────────────────────────────────────────
  Widget _buildEmergencyBanner(String dateStr, String timeStr) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_dangerDark, _danger, _dangerLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _danger.withOpacity(0.30),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EMERGENCY CASE',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Immediate treatment log',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.medical_services_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _bannerChip(Icons.calendar_today_rounded, dateStr),
              _bannerChip(Icons.access_time_rounded, timeStr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 13),
              const SizedBox(width: 6),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: _danger,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );

  Widget _buildField({
    required String id,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    int maxLines = 1,
  }) {
    final isFocused = _focusedField == id;
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _focusedField = hasFocus ? id : null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: _danger.withOpacity(0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          scrollPadding: const EdgeInsets.only(bottom: 160),
          keyboardType: TextInputType.multiline,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          cursorColor: _danger,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.blueGrey.shade300, fontSize: 13.5),
            labelStyle: TextStyle(
              color: isFocused ? _danger : Colors.blueGrey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: const TextStyle(
              color: _danger,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused ? _danger : Colors.blueGrey.shade400,
              size: 21,
            ),
            filled: true,
            fillColor: _fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _danger, width: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _glow({required Color color, required double radius}) => Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.0)],
            stops: const [0.0, 1.0],
          ),
        ),
      );
}