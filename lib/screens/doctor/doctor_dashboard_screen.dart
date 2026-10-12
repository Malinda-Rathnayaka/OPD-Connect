import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import 'doctor_leave_screen.dart';
import 'doctor_profile_screen.dart';
import 'live_queue_screen.dart';
import '../shared/emergency_records_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final DoctorService _service = DoctorService();
  int _selectedIndex = 0;
  bool _isSavingSession = false;

  String get _doctorId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ---- Theme tokens (aligned with auth screens) ----
  static const _bgTop = Color(0xFFEFF6FF);
  static const _bgMid = Color(0xFFF8FAFC);
  static const _bgBottom = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF2563EB);
  static const _primaryDark = Color(0xFF1E40AF);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _accent = Color(0xFF06B6D4);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E8F0);
  static const _fieldFill = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHome(),
      _buildLiveQueueTab(),
      _buildRecordedQueueTab(),
      DoctorProfileScreen(doctorId: _doctorId),
    ];
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _bgMid,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surface,
          border: const Border(top: BorderSide(color: _border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            backgroundColor: _surface,
            surfaceTintColor: _surface,
            elevation: 0,
            height: 70,
            indicatorColor: _primary.withOpacity(0.12),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) =>
                setState(() => _selectedIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 24),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: _primary,
                  size: 24,
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_outlined, size: 24),
                selectedIcon: Icon(
                  Icons.queue_rounded,
                  color: _primary,
                  size: 24,
                ),
                label: 'Live Queue',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined, size: 24),
                selectedIcon: Icon(
                  Icons.history_rounded,
                  color: _primary,
                  size: 24,
                ),
                label: 'Records',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 24),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: _primary,
                  size: 24,
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // HOME TAB
  // ─────────────────────────────────────────────────────────────
  Widget _buildHome() => _pageScaffold(
    title: 'Dashboard',
    child: _buildBackgroundStack(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getDoctorSessions(_doctorId),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return _message(
              'Unable to load sessions: ${snapshot.error}',
              Icons.error_outline,
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final sessions = snapshot.data!.docs.toList()
            ..sort((a, b) => _sessionDate(b).compareTo(_sessionDate(a)));
          final todayActive = sessions
              .where(
                (doc) =>
                    doc.data()['slotDate'] == _today() &&
                    doc.data()['status'] == 'IN_PROGRESS',
              )
              .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            physics: const BouncingScrollPhysics(),
            children: [
              _welcomeCard(),
              const SizedBox(height: 18),
              _startSessionCta(),
              const SizedBox(height: 22),
              _summaryCards(todayActive),
              const SizedBox(height: 26),
              _todayAppointmentsCard(),
              const SizedBox(height: 22),
              _leaveCard(),
              const SizedBox(height: 26),
              _emergencyRecordsCard(),
              const SizedBox(height: 26),
              _sectionHeader('Sessions'),
              const SizedBox(height: 14),
              if (sessions.isEmpty)
                _message(
                  'No sessions yet. Create a slot and add patients to its queue.',
                  Icons.calendar_today_outlined,
                )
              else
                ...sessions.map(_sessionCard),
            ],
          );
        },
      ),
    ),
  );

  Widget _emergencyRecordsCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmergencyRecordsScreen(doctorId: _doctorId),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: const Row(
            children: [
              Icon(Icons.emergency_outlined, color: Color(0xFFEA580C)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Records',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 3),
                    Text('Review emergency cases handled by you.'),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Color(0xFFEA580C)),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Full-width Start Session CTA card
  // ─────────────────────────────────────────────────────────────
  Widget _startSessionCta() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _isSavingSession ? null : () => _showSessionDialog(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _primary.withOpacity(0.10),
                _primaryLight.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primary.withOpacity(0.25), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryDark, _primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSavingSession
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start OPD Session',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Create a new slot for today or another date',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: _muted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveQueueTab() => _pageScaffold(
    title: 'Live Queue',
    child: _buildBackgroundStack(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getDoctorSessions(_doctorId),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return _message(
              'Unable to load live sessions.',
              Icons.error_outline,
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final sessions = snapshot.data!.docs
              .where((doc) => doc.data()['status'] == 'IN_PROGRESS')
              .toList();
          if (sessions.isEmpty)
            return _message(
              'No active session. Create one from Home.',
              Icons.queue_outlined,
            );

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            physics: const BouncingScrollPhysics(),
            children: sessions.map(_openQueueCard).toList(),
          );
        },
      ),
    ),
  );

  Widget _todayAppointmentsCard() => Container(
    decoration: _cardDecoration(),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getDoctorAppointments(_doctorId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Unable to load appointments.');
          }
          final appointments =
              (snapshot.data?.docs ?? []).where((doc) {
                final data = doc.data();
                return _appointmentDateKey(data['appointmentDate']) ==
                        _today() &&
                    (data['status']?.toString().toLowerCase() ?? '') !=
                        'cancelled';
              }).toList()..sort(
                (a, b) => (a.data()['appointmentTime'] ?? '')
                    .toString()
                    .compareTo((b.data()['appointmentTime'] ?? '').toString()),
              );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chipIcon(
                    icon: Icons.event_available_rounded,
                    color: _primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Today's booked appointments (${appointments.length})",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (appointments.isEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _fieldFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blueGrey.shade400,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'No appointments for today. Start a session after patients book a slot.',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...appointments.map(
                  (doc) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.person_outline_rounded,
                            color: _primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.data()['patientName']?.toString() ??
                                    'Patient',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: _ink,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${doc.data()['appointmentTime'] ?? 'Time not set'} · '
                                'Token ${doc.data()['tokenNumber'] ?? 'Not assigned'}',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );

  Widget _leaveCard() => Container(
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2563EB).withOpacity(0.06),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DoctorLeaveScreen()),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage Availability & Leaves',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: _ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Submit and track leave requests',
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _fieldFill,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: _muted,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

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
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: -0.2,
        ),
      ),
    ],
  );

  Widget _buildRecordedQueueTab() => _pageScaffold(
    title: 'Records',
    child: _buildBackgroundStack(
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _service.getDoctorSessions(_doctorId),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return _message(
              'Unable to load recorded sessions.',
              Icons.error_outline,
            );
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final sessions = snapshot.data!.docs;
          if (sessions.isEmpty)
            return _message('No recorded sessions yet.', Icons.history);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            physics: const BouncingScrollPhysics(),
            children: sessions.map((session) {
              final data = session.data();
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.getCompletedRecords(session.id),
                builder: (context, records) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: _cardDecoration(),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => _showRecords(
                        session.id,
                        data['timeSlot']?.toString() ?? 'Session',
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.folder_copy_outlined,
                                color: _accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${data['slotDate'] ?? ''} · ${data['timeSlot'] ?? 'OPD Session'}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: _ink,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${records.data?.docs.length ?? 0} patients treated',
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _fieldFill,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _border),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: _muted,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    ),
  );

  // ─────────────────────────────────────────────────────────────
  // Background stack with soft blue glows
  // ─────────────────────────────────────────────────────────────
  Widget _buildBackgroundStack({required Widget child}) {
    return Stack(
      children: [
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
        Positioned(
          top: -160,
          left: -120,
          child: _glow(
            color: const Color(0xFF93C5FD).withOpacity(0.35),
            radius: 260,
          ),
        ),
        Positioned(
          top: 100,
          right: -160,
          child: _glow(
            color: const Color(0xFFBFDBFE).withOpacity(0.45),
            radius: 240,
          ),
        ),
        Positioned(
          bottom: -180,
          left: -100,
          child: _glow(
            color: const Color(0xFFDBEAFE).withOpacity(0.55),
            radius: 280,
          ),
        ),
        child,
      ],
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

  // ─────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────
  Widget _pageScaffold({
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) => Scaffold(
    resizeToAvoidBottomInset: true,
    backgroundColor: _bgMid,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      centerTitle: false,
      title: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [_ink, _primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(rect),
        child: Text(
          title,
          softWrap: false,
          overflow: TextOverflow.visible,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 24,
            letterSpacing: -0.6,
          ),
        ),
      ),
      actions: [
        ...?actions,
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: _surface,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: _primary.withOpacity(0.2),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _confirmLogout,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 18,
                  color: _muted,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    body: child,
  );

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Sign out?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You will need to sign in again to access the doctor dashboard.',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          _buildGlowButton(
            label: 'Sign out',
            onTap: () => Navigator.pop(dialogContext, true),
            icon: Icons.logout,
            compact: true,
          ),
        ],
      ),
    );
    if (shouldLogout != true) return;
    try {
      await AuthService().signOut();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not sign out: $error')));
      }
    }
  }

  Widget _welcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      padding: const EdgeInsets.all(22),
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
            color: _primary.withOpacity(0.32),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dr. ${user?.displayName ?? user?.email ?? 'Doctor'}',
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
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
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
                  Icons.medical_services_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  Widget _summaryCards(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> sessions,
  ) {
    if (sessions.isEmpty)
      return Row(
        children: [
          _stat('Booked', 0, Icons.event_available_outlined, _primary),
          _stat('Seen', 0, Icons.check_circle_outline, const Color(0xFF10B981)),
          _stat(
            'Remaining',
            0,
            Icons.hourglass_bottom_rounded,
            const Color(0xFFF59E0B),
          ),
        ],
      );
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getSessionQueue(sessions.first.id),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final seen = docs
            .where((d) => d.data()['status'] == 'COMPLETED')
            .length;
        final remaining = docs
            .where(
              (d) =>
                  ['ARRIVED', 'IN_CONSULTATION'].contains(d.data()['status']),
            )
            .length;
        return Row(
          children: [
            _stat(
              'Booked',
              docs.length,
              Icons.event_available_outlined,
              _primary,
            ),
            _stat(
              'Seen',
              seen,
              Icons.check_circle_outline,
              const Color(0xFF10B981),
            ),
            _stat(
              'Remaining',
              remaining,
              Icons.hourglass_bottom_rounded,
              const Color(0xFFF59E0B),
            ),
          ],
        );
      },
    );
  }

  Widget _stat(String label, int count, IconData icon, Color color) => Expanded(
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sessionCard(QueryDocumentSnapshot<Map<String, dynamic>> session) {
    final data = session.data();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getSessionQueue(session.id),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final seen = docs
            .where((d) => d.data()['status'] == 'COMPLETED')
            .length;
        final remaining = docs
            .where(
              (d) =>
                  ['ARRIVED', 'IN_CONSULTATION'].contains(d.data()['status']),
            )
            .length;
        final isActive = data['status'] == 'IN_PROGRESS';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: _cardDecoration(),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _openLiveQueue(session.id),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isActive
                              ? [_primary, _primaryDark]
                              : [
                                  const Color(0xFF94A3B8),
                                  const Color(0xFF64748B),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: _primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: const Icon(
                        Icons.calendar_month_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['slotDate'] ?? ''} · ${data['timeSlot'] ?? 'OPD Session'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                              color: _ink,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _statusPill(
                                isActive ? 'Active' : 'Completed',
                                isActive ? const Color(0xFF10B981) : _muted,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${docs.length} patients',
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Seen: $seen  •  Remaining: $remaining',
                            style: const TextStyle(color: _muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Manage session',
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _fieldFill,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: _muted,
                          size: 18,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      onSelected: (action) =>
                          _handleSessionAction(action, session),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit session / patients'),
                        ),
                        PopupMenuItem(
                          value: data['status'] == 'IN_PROGRESS'
                              ? 'complete'
                              : 'reopen',
                          child: Text(
                            data['status'] == 'IN_PROGRESS'
                                ? 'Mark completed'
                                : 'Reopen session',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete session'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statusPill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    ),
  );

  Future<void> _handleSessionAction(
    String action,
    QueryDocumentSnapshot<Map<String, dynamic>> session,
  ) async {
    try {
      if (action == 'edit') {
        await _showSessionDialog(session: session);
      } else if (action == 'complete' || action == 'reopen') {
        await _service.setSessionStatus(
          session.id,
          action == 'complete' ? 'COMPLETED' : 'IN_PROGRESS',
        );
      } else if (action == 'delete' && mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Delete session?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            content: const Text(
              'This removes the session queue and its session records. Patient medical histories are retained.',
              style: TextStyle(height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              _buildGlowButton(
                label: 'Delete',
                onTap: () => Navigator.pop(dialogContext, true),
                compact: true,
              ),
            ],
          ),
        );
        if (confirmed == true) await _service.deleteSession(session.id);
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Session update failed: $error')),
        );
    }
  }

  Widget _openQueueCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: _cardDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openLiveQueue(doc.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc.data()['timeSlot']?.toString() ?? 'OPD Session',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _ink,
                            fontSize: 14.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          doc.data()['slotDate']?.toString() ?? '',
                          style: const TextStyle(color: _muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: _primary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _message(String text, IconData icon) => Center(
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
            child: Icon(icon, size: 40, color: _primary),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

  Widget _chipIcon({required IconData icon, required Color color}) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(icon, color: color, size: 18),
  );

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  String _appointmentDateKey(dynamic value) {
    if (value is Timestamp || value is DateTime) {
      final date = value is Timestamp
          ? value.toDate().toLocal()
          : (value as DateTime).toLocal();
      return date.toIso8601String().substring(0, 10);
    }
    final text = value?.toString().trim() ?? '';
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return parsed.toLocal().toIso8601String().substring(0, 10);
    }
    if (text.toLowerCase() == 'today') return _today();
    if (text.toLowerCase() == 'tomorrow') {
      return DateTime.now()
          .add(const Duration(days: 1))
          .toIso8601String()
          .substring(0, 10);
    }
    return '';
  }

  DateTime _sessionDate(QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
      DateTime.tryParse(doc.data()['slotDate']?.toString() ?? '') ??
      DateTime.fromMillisecondsSinceEpoch(0);

  // ─────────────────────────────────────────────────────────────
  // Modern OPD Session Dialog
  // Date is DISPLAY-ONLY (always today) — user cannot change it.
  // ─────────────────────────────────────────────────────────────
  Future<void> _showSessionDialog({
    QueryDocumentSnapshot<Map<String, dynamic>>? session,
  }) async {
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) return;
    setState(() => _isSavingSession = true);
    try {
      final existingQueue = session == null
          ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
          : (await _service.getSessionQueue(session.id).first).docs;
      final patientById = <String, Map<String, dynamic>>{};
      for (final queueDoc in existingQueue) {
        final data = queueDoc.data();
        final id = data['patientId']?.toString();
        if (id != null && !patientById.containsKey(id)) {
          patientById[id] = {
            'id': id,
            'name': data['patientName'] ?? 'Patient $id',
            'nic': data['nic'] ?? '',
            'phone': data['phone'] ?? '',
            'email': data['email'] ?? '',
          };
        }
      }
      var availablePatients = patientById.values.toList()
        ..sort(
          (a, b) => a['name'].toString().toLowerCase().compareTo(
            b['name'].toString().toLowerCase(),
          ),
        );

      // ── Date is ALWAYS today — not editable ──
      final selectedDate = _today();

      // For editing an existing session, prefill slot from that session.
      final initialData = session?.data();
      String selectedSlot =
          initialData?['timeSlot']?.toString() ?? '09:00 AM - 12:00 PM';
      final initialSlot = selectedSlot;

      final bookedPatients = await _service.getAppointmentsForSlot(
        doctorId: doctor.uid,
        slotDate: selectedDate,
        timeSlot: selectedSlot,
      );
      final patientsById = <String, Map<String, dynamic>>{
        for (final patient in availablePatients)
          patient['id'].toString(): patient,
      };
      for (final patient in bookedPatients) {
        patientsById[patient['id'].toString()] = patient;
      }
      availablePatients = patientsById.values.toList()
        ..sort(
          (a, b) => a['name'].toString().toLowerCase().compareTo(
            b['name'].toString().toLowerCase(),
          ),
        );
      if (!mounted) return;

      const slotOptions = [
        '09:00 AM - 12:00 PM',
        '01:00 PM - 03:00 PM',
        '03:30 PM - 05:30 PM',
      ];

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withOpacity(0.45),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final isCreating = session == null;
            // When editing, only allow save if slot changed.
            final canSave = isCreating || selectedSlot != initialSlot;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: DraggableScrollableSheet(
                initialChildSize: 0.88,
                minChildSize: 0.6,
                maxChildSize: 0.95,
                expand: false,
                builder: (context, scrollController) => Container(
                  decoration: const BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // ── Drag handle ──
                      Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(top: 12, bottom: 6),
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      // ── Hero header ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_primaryDark, _primaryLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                isCreating
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.edit_calendar_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isCreating
                                        ? 'Start OPD Session'
                                        : 'Edit OPD Session',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: _ink,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isCreating
                                        ? 'Create a slot and review booked patients'
                                        : 'Update slot details for this session',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: _muted,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Close button
                            Material(
                              color: _fieldFill,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => Navigator.pop(sheetContext),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _border),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Scrollable body ──
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                          children: [
                            // ── Date (display only) ──
                            _sheetSectionLabel('SESSION DATE'),
                            const SizedBox(height: 8),
                            _readOnlyDateCard(selectedDate: selectedDate),

                            const SizedBox(height: 22),

                            // ── Time slot chips ──
                            _sheetSectionLabel('TIME SLOT'),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: slotOptions.map((slot) {
                                final selected = slot == selectedSlot;
                                return GestureDetector(
                                  onTap: () {
                                    setDialogState(() => selectedSlot = slot);
                                    _service
                                        .getAppointmentsForSlot(
                                          doctorId: doctor.uid,
                                          slotDate: selectedDate,
                                          timeSlot: slot,
                                        )
                                        .then(
                                          (patients) => setDialogState(
                                            () => availablePatients = patients,
                                          ),
                                        );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: selected
                                          ? const LinearGradient(
                                              colors: [_primaryDark, _primary],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: selected ? null : _fieldFill,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: selected
                                            ? Colors.transparent
                                            : _border,
                                        width: 1.2,
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: _primary.withOpacity(
                                                  0.3,
                                                ),
                                                blurRadius: 14,
                                                offset: const Offset(0, 6),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 16,
                                          color: selected
                                              ? Colors.white
                                              : _muted,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          slot,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: selected
                                                ? Colors.white
                                                : _ink,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // ── Patient counter row ──
                            Row(
                              children: [
                                _sheetSectionLabel('BOOKED PATIENTS'),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${availablePatients.length}',
                                    style: const TextStyle(
                                      color: _primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (availablePatients.isEmpty)
                              _emptyPatientsState()
                            else
                              ...availablePatients.map(
                                (patient) => _patientTile(patient),
                              ),

                            const SizedBox(height: 8),
                          ],
                        ),
                      ),

                      // ── Sticky footer ──
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 18),
                        decoration: BoxDecoration(
                          color: _surface,
                          border: const Border(
                            top: BorderSide(color: _border, width: 1),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(sheetContext),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: const BorderSide(
                                      color: _border,
                                      width: 1.4,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    foregroundColor: _ink,
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: canSave
                                        ? [
                                            BoxShadow(
                                              color: _primary.withOpacity(0.35),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: !canSave
                                        ? null
                                        : () async {
                                            Navigator.pop(sheetContext);
                                            await _saveSession(
                                              session: session,
                                              doctorId: doctor.uid,
                                              doctorName:
                                                  doctor.displayName ??
                                                  doctor.email ??
                                                  'Doctor',
                                              timeSlot: selectedSlot,
                                              slotDate: selectedDate,
                                              patients: null,
                                            );
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: _primary
                                          .withOpacity(0.35),
                                      disabledForegroundColor: Colors.white
                                          .withOpacity(0.7),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isCreating
                                              ? Icons.play_arrow_rounded
                                              : Icons.check_rounded,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isCreating
                                              ? 'Create Session'
                                              : 'Save Changes',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load patients: $error')),
        );
    } finally {
      if (mounted) setState(() => _isSavingSession = false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Modern sheet helpers for the OPD session dialog
  // ─────────────────────────────────────────────────────────────
  Widget _sheetSectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      color: _muted,
      letterSpacing: 1.2,
    ),
  );

  // Read-only date card — displays today's date, no tap action.
  Widget _readOnlyDateCard({required String selectedDate}) {
    final parsed = DateTime.tryParse(selectedDate);
    final display = parsed != null
        ? '${_weekdayName(parsed.weekday)}, ${_monthName(parsed.month)} ${parsed.day}, ${parsed.year}'
        : selectedDate;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_primaryDark, _primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today',
                  style: TextStyle(
                    fontSize: 11,
                    color: _muted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  display,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          // Small "locked" indicator — communicates it's not editable
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.lock_outline_rounded, size: 12, color: _muted),
                SizedBox(width: 4),
                Text(
                  'Fixed',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientTile(Map<String, dynamic> patient) {
    final name = patient['name']?.toString().trim() ?? 'Patient';
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : 'P';
    final phone = patient['phone']?.toString().trim() ?? '';
    final nic = patient['nic']?.toString().trim() ?? '';
    final detail = phone.isNotEmpty
        ? phone
        : nic.isNotEmpty
        ? 'NIC · $nic'
        : 'Contact details unavailable';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primary.withOpacity(0.16),
                        _primaryLight.withOpacity(0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _primary.withOpacity(0.18)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          fontSize: 14,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            phone.isNotEmpty
                                ? Icons.phone_rounded
                                : Icons.badge_outlined,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              detail,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Subtle status pill (no checkbox — per your request)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Booked',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
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

  Widget _emptyPatientsState() => Container(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
    decoration: BoxDecoration(
      color: _fieldFill,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _border),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.person_search_rounded,
            color: _primary,
            size: 26,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'No booked patients yet',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _ink,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Patients who book this slot will appear here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
        ),
      ],
    ),
  );

  // Small date helpers (needed by _readOnlyDateCard)
  String _weekdayName(int w) =>
      const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][w - 1];

  String _monthName(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];

  Future<void> _saveSession({
    required QueryDocumentSnapshot<Map<String, dynamic>>? session,
    required String doctorId,
    required String doctorName,
    required String timeSlot,
    required String slotDate,
    required List<Map<String, dynamic>>? patients,
  }) async {
    setState(() => _isSavingSession = true);
    try {
      final leaveReason = await _service.getApprovedLeaveReason(
        doctorId,
        slotDate,
      );
      if (leaveReason != null) {
        throw StateError(
          'You have an approved leave on this date (Reason: $leaveReason). '
          'You cannot schedule or start an OPD session.',
        );
      }
      if (session == null) {
        final id = await _service.startAppointmentSession(
          doctorId: doctorId,
          doctorName: doctorName,
          timeSlot: timeSlot,
          slotDate: slotDate,
        );
        if (mounted) _openLiveQueue(id);
      } else {
        await _service.updateSession(
          sessionId: session.id,
          timeSlot: timeSlot,
          slotDate: slotDate,
          patients: patients,
        );
      }
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Session saved.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save session: $error')),
        );
    } finally {
      if (mounted) setState(() => _isSavingSession = false);
    }
  }

  void _openLiveQueue(String sessionId) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => LiveQueueScreen(sessionId: sessionId)),
  );

  Future<void> _showRecords(String sessionId, String title) async {
    try {
      final records = await _service.getCompletedRecords(sessionId).first;
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: ListView(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 8),
                ...records.docs.map(
                  (doc) => Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _fieldFill,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: _primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                doc.data()['patientName']?.toString() ??
                                    'Patient',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${doc.data()['diagnosis'] ?? 'Treatment recorded'}\n${doc.data()['prescription'] ?? ''}',
                          style: const TextStyle(color: _muted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load records: $error')),
        );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Glow pill button (matches auth screens)
  // ─────────────────────────────────────────────────────────────
  Widget _buildGlowButton({
    required String label,
    required VoidCallback? onTap,
    IconData? icon,
    bool compact = false,
  }) {
    final height = compact ? 42.0 : 56.0;
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _primary.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 16 : 24,
                vertical: compact ? 8 : 12,
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            onPressed: onTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 13.5 : 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: compact ? 18 : 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Shared decoration helper (pure styling) ----
  BoxDecoration _cardDecoration({double radius = 18}) => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF2563EB).withOpacity(0.06),
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
