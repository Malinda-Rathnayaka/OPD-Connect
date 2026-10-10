import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/doctor/doctor_leave_model.dart';
import '../../services/doctor_service.dart';

class DoctorLeaveScreen extends StatefulWidget {
  const DoctorLeaveScreen({super.key});

  @override
  State<DoctorLeaveScreen> createState() => _DoctorLeaveScreenState();
}

class _DoctorLeaveScreenState extends State<DoctorLeaveScreen> {
  final DoctorService _service = DoctorService();

  // ---- Theme tokens (aligned with auth + dashboard) ----
  static const _bgTop = Color(0xFFEFF6FF);
  static const _bgMid = Color(0xFFF8FAFC);
  static const _bgBottom = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF2563EB);
  static const _primaryDark = Color(0xFF1E40AF);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _violet = Color(0xFF7C3AED);
  static const _violetDark = Color(0xFF6D28D9);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF8FAFC);

  String? _focusedField;

  String get _doctorId => FirebaseAuth.instance.currentUser?.uid ?? '';
  String get _doctorName =>
      FirebaseAuth.instance.currentUser?.displayName ??
      FirebaseAuth.instance.currentUser?.email ??
      'Doctor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                'Availability & Leaves',
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
              'MANAGE YOUR OPD AVAILABILITY',
              style: TextStyle(
                color: _violet,
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

          // 2. Subtle blue + violet glows
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
                color: const Color(0xFFC4B5FD).withOpacity(0.35), radius: 240),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: _glow(
                color: const Color(0xFFDBEAFE).withOpacity(0.55), radius: 280),
          ),

          // 3. Content
          StreamBuilder<List<DoctorLeaveModel>>(
            stream: _service.getDoctorLeaves(_doctorId),
            builder: (context, snapshot) {
              if (snapshot.hasError)
                return _message('Unable to load leave requests.');
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }
              final leaves = snapshot.data!;
              if (leaves.isEmpty) {
                return _emptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                physics: const BouncingScrollPhysics(),
                itemCount: leaves.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _leaveCard(leaves[index]),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Floating Action Button (glow pill)
  // ─────────────────────────────────────────────────────────────
  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _violet.withOpacity(0.45),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        backgroundColor: _violet,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        onPressed: () => _showLeaveDialog(),
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text(
          'Request Leave',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Leave card (blue-tinted with violet accent)
  // ─────────────────────────────────────────────────────────────
  Widget _leaveCard(DoctorLeaveModel leave) {
    final pending = leave.status == 'PENDING';
    final colors = _statusColors(leave.status);
    return Container(
      decoration: _cardDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_violet, _violetDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _violet.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.event_busy_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _prettyDate(leave.date),
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        leave.date,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusPill(leave.status, colors.$1, colors.$2),
              ],
            ),
            const SizedBox(height: 14),
            _infoRow(
              icon: Icons.info_outline_rounded,
              label: 'Reason',
              value: leave.reason,
              color: _violet,
            ),
            if (leave.notes.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              _infoRow(
                icon: Icons.sticky_note_2_outlined,
                label: 'Notes',
                value: leave.notes,
                color: _primary,
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: _border),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionPill(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: _primary,
                    onTap: () => _showLeaveDialog(leave: leave),
                  ),
                  const SizedBox(width: 8),
                  _actionPill(
                    icon: Icons.delete_outline,
                    label: 'Cancel',
                    color: const Color(0xFFDC2626),
                    onTap: () => _deleteLeave(leave),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: fg,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: _ink,
                height: 1.45,
                fontFamily: 'Roboto',
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Empty state
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
                  color: _violet.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 40,
                  color: _violet,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No leave requests yet.',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap “Request Leave” to submit your first one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _message(String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      );

  // ─────────────────────────────────────────────────────────────
  // Leave dialog — styled fields
  // ─────────────────────────────────────────────────────────────
  Future<void> _showLeaveDialog({DoctorLeaveModel? leave}) async {
    final dateController =
        TextEditingController(text: leave?.date ?? _date(DateTime.now()));
    final reasonController = TextEditingController(text: leave?.reason ?? '');
    final notesController = TextEditingController(text: leave?.notes ?? '');
    try {
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_violet, _violetDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _violet.withOpacity(0.30),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                leave == null ? 'Request Leave' : 'Edit Leave Request',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: StatefulBuilder(
              builder: (context, setDialogState) => SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogField(
                      id: 'date',
                      controller: dateController,
                      label: 'Date',
                      icon: Icons.calendar_today_rounded,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate:
                              DateTime.tryParse(dateController.text) ??
                                  DateTime.now(),
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          dateController.text = _date(picked);
                          setDialogState(() {});
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    _dialogField(
                      id: 'reason',
                      controller: reasonController,
                      label: 'Reason',
                      hint: 'Personal, Medical, Academic, Emergency',
                      icon: Icons.info_outline_rounded,
                    ),
                    const SizedBox(height: 14),
                    _dialogField(
                      id: 'notes',
                      controller: notesController,
                      label: 'Additional notes',
                      icon: Icons.sticky_note_2_outlined,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Cancel',
                style: TextStyle(color: _muted, fontWeight: FontWeight.w600),
              ),
            ),
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withOpacity(0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 10,
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      if (dateController.text.isEmpty ||
                          reasonController.text.trim().isEmpty) {
                        return;
                      }
                      Navigator.pop(dialogContext, {
                        'date': dateController.text,
                        'reason': reasonController.text.trim(),
                        'notes': notesController.text.trim(),
                      });
                    },
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      if (result == null) return;
      if (leave == null) {
        final now = DateTime.now();
        await _service.createLeaveRequest(DoctorLeaveModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          doctorId: _doctorId,
          doctorName: _doctorName,
          date: result['date']!,
          reason: result['reason']!,
          notes: result['notes']!,
          status: 'PENDING',
          createdAt: now,
          updatedAt: now,
        ));
      } else {
        await _service.updateLeaveRequest(leave.id, result);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Leave request saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save leave request: $error')),
        );
      }
    } finally {
      dateController.dispose();
      reasonController.dispose();
      notesController.dispose();
    }
  }

  Widget _dialogField({
    required String id,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    final isFocused = _focusedField == id;
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _focusedField = hasFocus ? id : null);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: _primary.withOpacity(0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
            color: _ink,
          ),
          cursorColor: _primary,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.blueGrey.shade300, fontSize: 13),
            labelStyle: TextStyle(
              color: isFocused ? _primary : Colors.blueGrey.shade500,
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: const TextStyle(
              color: _primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused ? _primary : Colors.blueGrey.shade400,
              size: 20,
            ),
            filled: true,
            fillColor: _fieldFill,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _primary, width: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Delete confirm dialog (styled)
  // ─────────────────────────────────────────────────────────────
  Future<void> _deleteLeave(DoctorLeaveModel leave) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: Color(0xFFFEE2E2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.delete_outline_rounded,
            size: 32,
            color: Color(0xFFDC2626),
          ),
        ),
        title: const Text(
          'Cancel leave request?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'Cancel the request for ${_prettyDate(leave.date)}?',
          textAlign: TextAlign.center,
          style: const TextStyle(height: 1.5, color: _muted),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: _border),
                    ),
                  ),
                  child: const Text(
                    'No, keep it',
                    style: TextStyle(
                      color: _muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Yes, cancel',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _service.deleteLeaveRequest(leave.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not cancel leave request: $error')),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  (Color, Color) _statusColors(String status) => switch (status) {
        'APPROVED' => (const Color(0xFF059669), const Color(0xFFD1FAE5)),
        'REJECTED' => (const Color(0xFFDC2626), const Color(0xFFFEE2E2)),
        _ => (const Color(0xFFD97706), const Color(0xFFFEF3C7)),
      };

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

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _prettyDate(String iso) {
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final wd = weekdays[(parsed.weekday - 1).clamp(0, 6)];
    return '$wd, ${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }
}