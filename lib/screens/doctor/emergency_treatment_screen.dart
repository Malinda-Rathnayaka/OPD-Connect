import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/doctor_service.dart';

class EmergencyTreatmentScreen extends StatefulWidget {
  final String? sessionId;
  final String? queueDocId;

  const EmergencyTreatmentScreen({super.key, this.sessionId, this.queueDocId});

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

  // ---- Theme tokens (blue + white + red medical palette) ----
  static const Color _bgTop = Color(0xFFEFF6FF); // soft blue
  static const Color _bgMid = Color(0xFFF8FAFC); // clean white
  static const Color _bgBottom = Color(0xFFFFFFFF);

  static const Color _primary = Color(0xFF2563EB); // clinical blue

  static const Color _danger = Color(0xFFDC2626); // emergency red
  static const Color _dangerDark = Color(0xFF991B1B);
  static const Color _dangerLight = Color(0xFFEF4444);

  static const Color _ink = Color(0xFF0F172A);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to log emergency: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String dateStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
    String timeStr =
        "${now.hour.toString().padLeft(2, '0')}:"
        "${now.minute.toString().padLeft(2, '0')}";

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
            shadowColor: _primary.withValues(alpha: 0.20),
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
                  color: _primary,
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Log Emergency Case',
              style: TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _danger,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _danger.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
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
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Blue → white → white gradient (calm clinical backdrop)
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

          // 2. Soft blue + red radial glows (blue dominant, red accent)
          Positioned(
            top: -140,
            left: -120,
            child: _glow(
              color: const Color(0xFF93C5FD).withValues(alpha: 0.40),
              radius: 260,
            ),
          ),
          Positioned(
            top: 100,
            right: -160,
            child: _glow(
              color: const Color(0xFFFCA5A5).withValues(alpha: 0.35),
              radius: 240,
            ),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: _glow(
              color: const Color(0xFFDBEAFE).withValues(alpha: 0.55),
              radius: 280,
            ),
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

                // Section header — blue (calm intake)
                _sectionHeader('Patient Information', color: _primary),
                const SizedBox(height: 14),

                _buildField(
                  id: 'name',
                  label: 'Patient Name',
                  hint: 'e.g. Sunil Shantha',
                  controller: _nameController,
                  icon: Icons.person_outline_rounded,
                  accent: _primary,
                  isRequired: true,
                ),
                const SizedBox(height: 14),
                _buildField(
                  id: 'nic',
                  label: 'NIC / Phone Number',
                  hint: 'e.g. 199012345678 or 0712345678',
                  controller: _nicController,
                  icon: Icons.badge_outlined,
                  accent: _primary,
                ),

                const SizedBox(height: 22),
                // Section header — red (urgent)
                _sectionHeader('Emergency Details', color: _danger),
                const SizedBox(height: 14),

                _buildField(
                  id: 'reason',
                  label: 'Emergency Reason / Symptom',
                  hint: 'e.g. Severe Chest Pain / Asthma Attack',
                  controller: _reasonController,
                  icon: Icons.warning_amber_rounded,
                  accent: _danger,
                  isRequired: true,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _buildField(
                  id: 'treatment',
                  label: 'Treatment / Injection Given',
                  hint: 'e.g. Nebulized / Hydrocortisone IV',
                  controller: _treatmentController,
                  icon: Icons.medication_outlined,
                  accent: _danger,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                _buildField(
                  id: 'notes',
                  label: 'Additional Clinical Notes',
                  hint: 'e.g. Sent to ICU Ward 02',
                  controller: _notesController,
                  icon: Icons.sticky_note_2_outlined,
                  accent: _danger,
                  maxLines: 2,
                ),

                const SizedBox(height: 28),

                // Save button with red glow — flex-safe, no overflow
                _buildSaveButton(),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Save button (overflow-safe)
  // ─────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _danger.withValues(alpha: 0.40),
                  blurRadius: 22,
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
                disabledBackgroundColor: _danger.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: _isSaving ? null : _saveEmergencyRecord,
              child: _isSaving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.save_rounded, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Save & Update Patient History',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Emergency banner (red hero, blue-tinted white glass chips)
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
            color: _danger.withValues(alpha: 0.32),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.emergency_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'EMERGENCY CASE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Immediate treatment log',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(width: 12),
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
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
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
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

  // Section header with configurable accent color
  Widget _sectionHeader(String title, {required Color color}) => Row(
    children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.2,
          ),
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
    required Color accent,
    bool isRequired = false,
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
                    color: accent.withValues(alpha: 0.18),
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
          cursorColor: accent,
          decoration: InputDecoration(
            labelText: isRequired ? '$label *' : label,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.blueGrey.shade300,
              fontSize: 13.5,
            ),
            labelStyle: TextStyle(
              color: isFocused ? accent : Colors.blueGrey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              color: accent,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused ? accent : Colors.blueGrey.shade400,
              size: 21,
            ),
            filled: true,
            fillColor: _fieldFill,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 16,
            ),
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
              borderSide: BorderSide(color: accent, width: 1.6),
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
        colors: [color, color.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      ),
    ),
  );
}
