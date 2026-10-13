import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'active_consultation_screen.dart';
import 'emergency_treatment_screen.dart';

class LiveQueueScreen extends StatelessWidget {
  final String sessionId;

  const LiveQueueScreen({super.key, required this.sessionId});

  // ---- Theme tokens (aligned with the rest of the app) ----
  static const Color _bgTop = Color(0xFFEFF6FF);
  static const Color _bgMid = Color(0xFFF8FAFC);
  static const Color _bgBottom = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _primaryDark = Color(0xFF1E40AF);
  static const Color _primaryLight = Color(0xFF3B82F6);
  static const Color _ink = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _surface = Colors.white;
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _fieldFill = Color(0xFFF8FAFC);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _success = Color(0xFF10B981);
  static const Color _warn = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgMid,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LIVE QUEUE PANEL',
              style: TextStyle(
                color: _primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [_ink, _primary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(rect),
              child: const Text(
                'Live Queue',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
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
              color: const Color(0xFF93C5FD).withValues(alpha: 0.35),
              radius: 260,
            ),
          ),
          Positioned(
            top: 100,
            right: -160,
            child: _glow(
              color: const Color(0xFFBFDBFE).withValues(alpha: 0.45),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('sessions')
                .doc(sessionId)
                .collection('queue')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: _primary),
                );
              }

              final allDocs = snapshot.data!.docs;

              // Group by status — DO NOT change logic, only presentation
              final inConsultationDocs = allDocs
                  .where((d) => d['status'] == 'IN_CONSULTATION')
                  .toList();
              final upcomingDocs = allDocs
                  .where((d) => d['status'] == 'ARRIVED')
                  .toList();
              final completedDocs = allDocs
                  .where(
                    (d) =>
                        d['status'] == 'COMPLETED' ||
                        d['status'] == 'CANCELLED' ||
                        d['status'] == 'SKIPPED',
                  )
                  .toList();

              final activePatient = inConsultationDocs.isNotEmpty
                  ? inConsultationDocs.first
                  : null;

              // Total slot capacity = all tokens issued for this session
              final int totalSlots = allDocs.length;
              final int filledSlots =
                  inConsultationDocs.length + upcomingDocs.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero overview card ──
                    _buildHeroCard(
                      totalSlots: totalSlots,
                      filledSlots: filledSlots,
                      waitingCount: upcomingDocs.length,
                      hasActive: activePatient != null,
                    ),
                    const SizedBox(height: 22),

                    // ── Circular queue visualization ──
                    _sectionHeader('Queue Ring'),
                    const SizedBox(height: 6),
                    const Padding(
                      padding: EdgeInsets.only(left: 14, bottom: 12),
                      child: Text(
                        'Filled circles are occupied seats. Faded rings are vacancies.',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11.5,
                          height: 1.35,
                        ),
                      ),
                    ),
                    _buildCircularQueue(
                      context: context,
                      activePatient: activePatient,
                      upcomingDocs: upcomingDocs,
                      completedDocs: completedDocs,
                      totalSlots: totalSlots,
                    ),
                    const SizedBox(height: 26),

                    // ── Now Serving detail card (unchanged behavior) ──
                    _sectionHeader('Now Serving'),
                    const SizedBox(height: 14),
                    if (activePatient != null)
                      _buildActiveConsultationCard(context, activePatient)
                    else
                      _emptyActive(),
                    const SizedBox(height: 26),

                    // ── Upcoming list (unchanged behavior) ──
                    _sectionHeader('Upcoming Patients'),
                    const SizedBox(height: 14),
                    if (upcomingDocs.isEmpty)
                      _emptyUpcoming()
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: upcomingDocs.length,
                        itemBuilder: (context, index) {
                          return _buildUpcomingCard(upcomingDocs[index]);
                        },
                      ),
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
  // Circular queue visualization
  // ─────────────────────────────────────────────────────────────
  Widget _buildCircularQueue({
    required BuildContext context,
    required QueryDocumentSnapshot? activePatient,
    required List<QueryDocumentSnapshot> upcomingDocs,
    required List<QueryDocumentSnapshot> completedDocs,
    required int totalSlots,
  }) {
    // Build ordered list of slots by 'order' field so circles read naturally.
    // Filled = patient still present. Vacant = already left (completed/skipped).
    final List<QueryDocumentSnapshot> allSlots = [
      ?activePatient,
      ...upcomingDocs,
      ...completedDocs,
    ];

    // Sort by order if available, so ring reads left→right in queue order
    allSlots.sort((a, b) {
      final ao = (a.data() as Map<String, dynamic>)['order'];
      final bo = (b.data() as Map<String, dynamic>)['order'];
      final ai = ao is int ? ao : int.tryParse('$ao') ?? 9999;
      final bi = bo is int ? bo : int.tryParse('$bo') ?? 9999;
      return ai.compareTo(bi);
    });

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(color: _primary, label: 'In consultation'),
              const SizedBox(width: 14),
              _legendDot(color: _success, label: 'Waiting'),
              const SizedBox(width: 14),
              _legendDot(color: _muted.withValues(alpha: 0.35), label: 'Left'),
            ],
          ),
          const SizedBox(height: 20),

          // Circular grid
          if (allSlots.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.radio_button_unchecked_rounded,
                      color: _primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No tokens issued yet',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Circles will appear here as patients join the queue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            )
          else
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: allSlots.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status']?.toString() ?? '';
                final token = data['tokenNo']?.toString() ?? '—';
                final name = data['patientName']?.toString() ?? 'Patient';

                // Determine appearance by status
                Color fillColor;
                Color ringColor;
                double fillOpacity;
                bool isEmpty;
                bool isPulsing;

                switch (status) {
                  case 'IN_CONSULTATION':
                    fillColor = _primary;
                    ringColor = _primary;
                    fillOpacity = 1.0;
                    isEmpty = false;
                    isPulsing = true;
                    break;
                  case 'ARRIVED':
                    fillColor = _success;
                    ringColor = _success;
                    fillOpacity = 0.85;
                    isEmpty = false;
                    isPulsing = false;
                    break;
                  case 'COMPLETED':
                    fillColor = _muted;
                    ringColor = _muted;
                    fillOpacity = 0.18; // drained
                    isEmpty = true;
                    isPulsing = false;
                    break;
                  case 'SKIPPED':
                  case 'CANCELLED':
                    fillColor = _warn;
                    ringColor = _warn;
                    fillOpacity = 0.18; // drained
                    isEmpty = true;
                    isPulsing = false;
                    break;
                  default:
                    fillColor = _muted;
                    ringColor = _muted;
                    fillOpacity = 0.10;
                    isEmpty = true;
                    isPulsing = false;
                }

                return _queueCircle(
                  context: context,
                  doc: doc,
                  token: token,
                  name: name,
                  status: status,
                  fillColor: fillColor,
                  ringColor: ringColor,
                  fillOpacity: fillOpacity,
                  isEmpty: isEmpty,
                  isPulsing: isPulsing,
                );
              }).toList(),
            ),

          const SizedBox(height: 18),

          // Progress bar at bottom
          _buildSlotProgress(
            filled:
                totalSlots -
                completedDocs.length, // treat completed/cancelled as "drained"
            total: totalSlots,
          ),
        ],
      ),
    );
  }

  Widget _queueCircle({
    required BuildContext context,
    required QueryDocumentSnapshot doc,
    required String token,
    required String name,
    required String status,
    required Color fillColor,
    required Color ringColor,
    required double fillOpacity,
    required bool isEmpty,
    required bool isPulsing,
  }) {
    const double size = 62.0;

    return GestureDetector(
      onTap: () {
        // Only the active patient circle navigates — matches prior behavior.
        if (status == 'IN_CONSULTATION') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveConsultationScreen(sessionId: sessionId),
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size + 12,
            height: size + 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing outer glow for active
                if (isPulsing)
                  Container(
                    width: size + 12,
                    height: size + 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: fillColor.withValues(alpha: 0.45),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),

                // Main circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Fill with gradient when occupied
                    gradient: isEmpty
                        ? null
                        : LinearGradient(
                            colors: [
                              fillColor.withValues(alpha: fillOpacity),
                              fillColor.withValues(alpha: fillOpacity * 0.75),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    // Faded fill when drained
                    color: isEmpty ? fillColor.withValues(alpha: fillOpacity) : null,
                    // Ring border — brighter when filled
                    border: Border.all(
                      color: isEmpty
                          ? ringColor.withValues(alpha: 0.35)
                          : ringColor.withValues(alpha: 0.85),
                      width: isEmpty ? 1.5 : 2.0,
                    ),
                    boxShadow: isEmpty
                        ? []
                        : [
                            BoxShadow(
                              color: fillColor.withValues(alpha: 0.30),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                  ),
                  alignment: Alignment.center,
                  child: isEmpty
                      ? Icon(
                          Icons.remove_rounded,
                          size: 22,
                          color: ringColor.withValues(alpha: 0.55),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              token,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                name.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Small status label under circle
          Text(
            _statusShortLabel(status),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: isEmpty
                  ? _muted.withValues(alpha: 0.7)
                  : fillColor.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotProgress({required int filled, required int total}) {
    final double ratio = total == 0 ? 0 : (filled / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_alt_outlined, size: 14, color: _muted),
            const SizedBox(width: 6),
            Text(
              '$filled of $total seats occupied',
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Text(
              '${(ratio * 100).round()}%',
              style: const TextStyle(
                color: _primary,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              Container(height: 8, color: _border),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                widthFactor: ratio,
                child: Container(
                  height: 8,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryDark, _primaryLight],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _legendDot({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _statusShortLabel(String status) {
    switch (status) {
      case 'IN_CONSULTATION':
        return 'ACTIVE';
      case 'ARRIVED':
        return 'WAITING';
      case 'COMPLETED':
        return 'DONE';
      case 'SKIPPED':
        return 'SKIPPED';
      case 'CANCELLED':
        return 'CANCELLED';
      default:
        return '—';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Hero overview card
  // ─────────────────────────────────────────────────────────────
  Widget _buildHeroCard({
    required int totalSlots,
    required int filledSlots,
    required int waitingCount,
    required bool hasActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryDark, _primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.32),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.28),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'OPD SESSION STATUS',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: hasActive
                      ? Colors.white.withValues(alpha: 0.22)
                      : Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: hasActive
                            ? const Color(0xFF4ADE80)
                            : Colors.white.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: hasActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80)
                                      .withValues(alpha: 0.7),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasActive ? 'ACTIVE' : 'IDLE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  label: 'Occupied',
                  value: filledSlots.toString(),
                  icon: Icons.groups_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _heroStat(
                  label: 'Waiting',
                  value: waitingCount.toString(),
                  icon: Icons.hourglass_bottom_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.20),
              ),
              Expanded(
                child: _heroStat(
                  label: 'Total',
                  value: totalSlots.toString(),
                  icon: Icons.confirmation_num_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat({
    required String label,
    required String value,
    required IconData icon,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    ),
  );

  // ─────────────────────────────────────────────────────────────
  // Active consultation card (unchanged behavior)
  // ─────────────────────────────────────────────────────────────
  Widget _buildActiveConsultationCard(
    BuildContext context,
    QueryDocumentSnapshot activePatient,
  ) {
    final patientData = activePatient.data() as Map<String, dynamic>;
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _primary.withValues(alpha: 0.30), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.14),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _primary.withValues(alpha: 0.08),
                  _primaryLight.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(21),
              ),
              border: Border(
                bottom: BorderSide(color: _primary.withValues(alpha: 0.14)),
              ),
            ),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: _primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        const Flexible(
                          child: Text(
                            'IN CONSULTATION',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, _primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.32),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Token ${activePatient['tokenNo']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primaryDark, _primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.32),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initial(activePatient['patientName']?.toString()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activePatient['patientName']?.toString() ??
                                'Patient',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Currently being seen',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FutureBuilder<String>(
                      future: _loadPatientDetail(patientData),
                      builder: (context, snapshot) => _infoChip(
                        Icons.contact_page_outlined,
                        snapshot.data ?? 'Loading patient detail...',
                      ),
                    ),
                    _infoChip(
                      Icons.schedule_rounded,
                      'Appt: ${patientData['apptTime'] ?? '—'}',
                    ),
                    if ((patientData['nic']?.toString().trim() ?? '')
                        .isNotEmpty)
                      _infoChip(
                        Icons.badge_outlined,
                        'NIC: ${patientData['nic']}',
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                _glowButton(
                  label: 'Open Patient Consultation',
                  icon: Icons.arrow_forward_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActiveConsultationScreen(sessionId: sessionId),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _danger,
                      side: BorderSide(
                        color: _danger.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      backgroundColor: _danger.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    icon: const Icon(Icons.priority_high_rounded, size: 18),
                    label: const Text(
                      'Skip for Emergency',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        fontSize: 13.5,
                      ),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmergencyTreatmentScreen(
                          sessionId: sessionId,
                          queueDocId: activePatient.id,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _loadPatientDetail(Map<String, dynamic> queueData) async {
    final phone = queueData['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty) return 'Phone: $phone';

    final email = queueData['email']?.toString().trim() ?? '';
    if (email.isNotEmpty) return 'Email: $email';

    final patientId = queueData['patientId']?.toString().trim() ?? '';
    if (patientId.isEmpty) return 'Patient detail unavailable';

    final firestore = FirebaseFirestore.instance;
    final patientDoc = await firestore
        .collection('patients')
        .doc(patientId)
        .get();
    final patient = patientDoc.data();
    final patientPhone = patient?['phone']?.toString().trim() ?? '';
    if (patientPhone.isNotEmpty) return 'Phone: $patientPhone';

    final userDoc = await firestore.collection('users').doc(patientId).get();
    final user = userDoc.data();
    final userPhone = user?['phone']?.toString().trim() ?? '';
    if (userPhone.isNotEmpty) return 'Phone: $userPhone';

    final userEmail = user?['email']?.toString().trim() ?? '';
    if (userEmail.isNotEmpty) return 'Email: $userEmail';

    final gender = patient?['gender']?.toString().trim() ?? '';
    final age = patient?['age']?.toString().trim() ?? '';
    if (gender.isNotEmpty && age.isNotEmpty) return '$gender · Age $age';
    if (gender.isNotEmpty) return gender;
    if (age.isNotEmpty) return 'Age $age';
    return 'Patient detail unavailable';
  }

  // ─────────────────────────────────────────────────────────────
  // Upcoming patient row (unchanged behavior)
  // ─────────────────────────────────────────────────────────────
  Widget _buildUpcomingCard(QueryDocumentSnapshot item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withValues(alpha: 0.14),
                        _primaryLight.withValues(alpha: 0.08),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _primary.withValues(alpha: 0.22),
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['tokenNo']?.toString() ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _primary,
                          letterSpacing: -0.4,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'TOKEN',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 7.5,
                          color: _primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['patientName']?.toString() ?? 'Patient',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _ink,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'NIC: ${item['nic'] ?? '—'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              '${item['apptTime'] ?? '—'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _success.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _success.withValues(alpha: 0.30)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 11,
                        color: _success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ARRIVED',
                        style: TextStyle(
                          color: _success,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
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
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _ink,
            letterSpacing: -0.2,
          ),
        ),
      ),
    ],
  );

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 1.1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: _muted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _muted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.40),
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
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(icon, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyActive() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _border, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: _primary.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.meeting_room_outlined,
            color: _primary,
            size: 30,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'No active consultation',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Call the next patient from the waiting list below.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
        ),
      ],
    ),
  );

  Widget _emptyUpcoming() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: _primary.withValues(alpha: 0.05),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.queue_outlined, color: _primary, size: 30),
        ),
        const SizedBox(height: 14),
        const Text(
          'No patients waiting',
          style: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Patients marked as ARRIVED will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
        ),
      ],
    ),
  );

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

  String _initial(String? name) {
    final trimmed = (name ?? '').trim();
    if (trimmed.isEmpty) return 'P';
    return trimmed.characters.first.toUpperCase();
  }
}
