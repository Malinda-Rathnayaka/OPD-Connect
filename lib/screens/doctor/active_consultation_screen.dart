import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/doctor_service.dart';

class ActiveConsultationScreen extends StatefulWidget {
  final String sessionId;

  const ActiveConsultationScreen({super.key, required this.sessionId});

  @override
  State<ActiveConsultationScreen> createState() =>
      _ActiveConsultationScreenState();
}

class _ActiveConsultationScreenState extends State<ActiveConsultationScreen> {
  final DoctorService _service = DoctorService();

  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _adviceController = TextEditingController();
  bool _isSaving = false;

  // ---- Theme tokens (aligned with auth + dashboard screens) ----
  static const _bgTop = Color(0xFFEFF6FF);
  static const _bgMid = Color(0xFFF8FAFC);
  static const _bgBottom = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF2563EB);
  static const _primaryDark = Color(0xFF1E40AF);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF8FAFC);

  String? _focusedField;

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
      backgroundColor: _bgMid,
      extendBodyBehindAppBar: false,
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
            shadowColor: _primary.withOpacity(0.2),
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
                  color: _ink,
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
                colors: [_ink, _primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(rect),
              child: const Text(
                'Active Consultation',
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
              'ROOM 04 • DR. KAMAL PERERA',
              style: TextStyle(
                color: _primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // 1. Soft light background gradient
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

          // 2. Subtle blue radial glows
          Positioned(
            top: -140,
            left: -120,
            child: _glow(
                color: const Color(0xFF93C5FD).withOpacity(0.35), radius: 260),
          ),
          Positioned(
            top: 100,
            right: -160,
            child: _glow(
                color: const Color(0xFFBFDBFE).withOpacity(0.45), radius: 240),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: _glow(
                color: const Color(0xFFDBEAFE).withOpacity(0.55), radius: 280),
          ),

          // 3. Content
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sessions')
                .doc(widget.sessionId)
                .collection('queue')
                .where('status', isEqualTo: 'IN_CONSULTATION')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _emptyState();
              }

              var activeDoc = snapshot.data!.docs.first;
              var patientData = activeDoc.data() as Map<String, dynamic>;
              String queueDocId = activeDoc.id;
              String patientId = patientData['patientId'];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _patientHeader(patientData),
                    const SizedBox(height: 16),

                    // Patient history
                    FutureBuilder<List<dynamic>>(
                      future: _service.fetchPatientHistory(patientId),
                      builder: (context, historySnapshot) {
                        return _historyCard(historySnapshot);
                      },
                    ),
                    const SizedBox(height: 22),

                    // Form section header
                    _sectionHeader('Consultation Notes'),
                    const SizedBox(height: 16),

                    // 1. Diagnosis
                    _buildField(
                      id: 'diagnosis',
                      controller: _diagnosisController,
                      label: 'Diagnosis / Disease',
                      hint: 'e.g. Acute Pharyngitis',
                      icon: Icons.medical_information_outlined,
                    ),
                    const SizedBox(height: 16),

                    // 2. Prescription
                    _buildField(
                      id: 'prescription',
                      controller: _prescriptionController,
                      label: 'Prescription (Medicines)',
                      hint: 'e.g. Paracetamol 500mg, Amoxicillin 500mg',
                      icon: Icons.medication_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // 3. Advice
                    _buildField(
                      id: 'advice',
                      controller: _adviceController,
                      label: 'Special Advice',
                      hint: 'e.g. Rest and hydration recommended',
                      icon: Icons.tips_and_updates_outlined,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 28),

                    // CTA
                    _buildGlowButton(
                      label: _isSaving
                          ? 'Saving…'
                          : 'Complete & Call Next Patient',
                      onTap: _isSaving
                          ? null
                          : () => _submit(
                                queueDocId: queueDocId,
                                patientId: patientId,
                                patientName: patientData['patientName']
                                        ?.toString() ??
                                    'Unknown Patient',
                                tokenNo:
                                    patientData['tokenNo']?.toString() ?? '',
                              ),
                      icon: Icons.arrow_forward_rounded,
                      loading: _isSaving,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Submit handler (logic unchanged)
  // ─────────────────────────────────────────────────────────────
  Future<void> _submit({
    required String queueDocId,
    required String patientId,
    required String patientName,
    required String tokenNo,
  }) async {
    if (_diagnosisController.text.isEmpty ||
        _prescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill Diagnosis and Prescription details'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _service.submitAndCallNext(
        sessionId: widget.sessionId,
        queueDocId: queueDocId,
        patientId: patientId,
        patientName: patientName,
        tokenNo: tokenNo,
        diagnosis: _diagnosisController.text,
        prescription: _prescriptionController.text,
        advice: _adviceController.text,
      );
      _diagnosisController.clear();
      _prescriptionController.clear();
      _adviceController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Treatment saved and next patient called.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save treatment: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Widgets
  // ─────────────────────────────────────────────────────────────

  Widget _emptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_search_rounded,
                  size: 40,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No patient currently in consultation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _patientHeader(Map<String, dynamic> patientData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.30),
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
                      'IN CONSULTATION',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      patientData['patientName']?.toString() ?? 'N/A',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerChip(
                  Icons.badge_outlined, 'NIC: ${patientData['nic'] ?? 'N/A'}'),
              _headerChip(Icons.phone_outlined,
                  'Phone: ${patientData['phone'] ?? 'N/A'}'),
              _headerChip(Icons.confirmation_number_outlined,
                  'Token ${patientData['tokenNo'] ?? '-'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
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

  Widget _historyCard(AsyncSnapshot<List<dynamic>> historySnapshot) {
    if (historySnapshot.hasData && historySnapshot.data!.isNotEmpty) {
      final records = historySnapshot.data!.reversed.toList();
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chipIcon(icon: Icons.history_rounded, color: _primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Previous Treatment History',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      fontSize: 14.5,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...records.map(
              (record) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            record['type']?.toString() ?? 'TREATMENT',
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          record['date']?.toString() ?? 'Unknown date',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _historyLine(
                        'Diagnosis', record['diagnosis'] ?? 'Not recorded'),
                    _historyLine('Treatment',
                        record['prescription'] ?? 'Not recorded'),
                    if ((record['advice'] ?? '').toString().isNotEmpty)
                      _historyLine('Notes', record['advice']),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _chipIcon(icon: Icons.person_add_alt_1_rounded, color: _primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'New Patient — no previous medical history recorded.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12.5,
            color: _ink,
            height: 1.4,
            fontFamily: 'Roboto',
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: _muted),
            ),
          ],
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
              color: _primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -0.2,
            ),
          ),
        ],
      );

  Widget _buildField({
    required String id,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
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
                    color: _primary.withOpacity(0.15),
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
          cursorColor: _primary,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.blueGrey.shade300, fontSize: 13.5),
            labelStyle: TextStyle(
              color: isFocused ? _primary : Colors.blueGrey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: const TextStyle(
              color: _primary,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused ? _primary : Colors.blueGrey.shade400,
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
              borderSide: const BorderSide(color: _primary, width: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool loading = false,
  }) {
    return SizedBox(
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
                  color: _primary.withOpacity(0.4),
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
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _primary.withOpacity(0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
              ),
              onPressed: onTap,
              child: loading
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
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 20),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipIcon({required IconData icon, required Color color}) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      );

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

  BoxDecoration _cardDecoration({double radius = 18}) => BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
}