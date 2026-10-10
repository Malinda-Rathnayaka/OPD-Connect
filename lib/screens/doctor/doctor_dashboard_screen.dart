import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/doctor_service.dart';
import 'doctor_leave_screen.dart';
import 'doctor_profile_screen.dart';
import 'live_queue_screen.dart';

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

  // ---- Modern theme tokens (aligned with auth screens) ----
  static const _bg = Color(0xFFF4F6FB);
  static const _primary = Color(0xFF2563EB);
  static const _primaryDark = Color(0xFF1E40AF);
  static const _primaryLight = Color(0xFF3B82F6);
  static const _accent = Color(0xFF06B6D4);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  static const _surface = Colors.white;
  static const _border = Color(0xFFE2E8F0);

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
      backgroundColor: _bg,
      body: pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _surface,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.06),
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
                selectedIcon: Icon(Icons.home_rounded, color: _primary, size: 24),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.queue_outlined, size: 24),
                selectedIcon: Icon(Icons.queue_rounded, color: _primary, size: 24),
                label: 'Live Queue',
              ),
              NavigationDestination(
                icon: Icon(Icons.history_outlined, size: 24),
                selectedIcon: Icon(Icons.history_rounded, color: _primary, size: 24),
                label: 'Records',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 24),
                selectedIcon: Icon(Icons.person_rounded, color: _primary, size: 24),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHome() => _pageScaffold(
    title: 'Dashboard',
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          onPressed: _isSavingSession ? null : () => _showSessionDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'Create Slot',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    ],
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
            const SizedBox(height: 22),
            _summaryCards(todayActive),
            const SizedBox(height: 26),
            _todayAppointmentsCard(),
            const SizedBox(height: 22),
            _leaveCard(),
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
  );

  Widget _buildLiveQueueTab() => _pageScaffold(
    title: 'Live Queue',
    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getDoctorSessions(_doctorId),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return _message('Unable to load live sessions.', Icons.error_outline);
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: _primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Today's booked appointments",
                      style: TextStyle(
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
                    color: _bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.grey.shade500,
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
                ...appointments.take(4).map(
                  (doc) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(12),
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
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
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
                  color: _bg,
                  borderRadius: BorderRadius.circular(8),
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
                              color: _bg,
                              borderRadius: BorderRadius.circular(8),
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
  );

  Widget _pageScaffold({
    required String title,
    required Widget child,
    List<Widget>? actions,
  }) => Scaffold(
    resizeToAvoidBottomInset: true,
    backgroundColor: _bg,
    appBar: AppBar(
      backgroundColor: _bg,
      surfaceTintColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w800,
          fontSize: 24,
          letterSpacing: -0.6,
        ),
      ),
      actions: [
        ...?actions,
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Material(
            color: _surface,
            shape: const CircleBorder(),
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
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Colors.white,
              size: 28,
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
                                isActive
                                    ? const Color(0xFF10B981)
                                    : _muted,
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
                          color: _bg,
                          borderRadius: BorderRadius.circular(8),
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
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
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

  Widget _openQueueCard(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) => Container(
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

  String _today() => DateTime.now().toIso8601String().substring(0, 10);

  String _appointmentDateKey(dynamic value) {
    if (value is Timestamp || value is DateTime) {
      final date = value is Timestamp ? value.toDate() : value as DateTime;
      return date.toIso8601String().substring(0, 10);
    }
    final text = value?.toString().trim() ?? '';
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return parsed.toIso8601String().substring(0, 10);
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
      final availablePatients = patientById.values.toList()
        ..sort(
          (a, b) => a['name'].toString().toLowerCase().compareTo(
            b['name'].toString().toLowerCase(),
          ),
        );
      final selected = existingQueue
          .map((doc) => doc.data()['patientId']?.toString())
          .whereType<String>()
          .toSet();
      final initialData = session?.data();
      String selectedSlot =
          initialData?['timeSlot']?.toString() ?? '09:00 AM - 12:00 PM';
      String selectedDate = initialData?['slotDate']?.toString() ?? _today();
      final initialSlot = selectedSlot;
      final initialDate = selectedDate;
      String filter = '';
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final filtered = availablePatients.where((patient) {
              final query = filter.toLowerCase();
              return query.isEmpty ||
                  patient['name'].toString().toLowerCase().contains(query) ||
                  patient['nic'].toString().toLowerCase().contains(query) ||
                  patient['phone'].toString().toLowerCase().contains(query);
            }).toList();
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                session == null ? 'Create OPD Slot' : 'Edit OPD Slot',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SizedBox(
                width: 480,
                height: MediaQuery.of(context).size.height * 0.62,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value:
                          [
                            '09:00 AM - 12:00 PM',
                            '01:00 PM - 03:00 PM',
                            '03:30 PM - 05:30 PM',
                          ].contains(selectedSlot)
                          ? selectedSlot
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Session time',
                      ),
                      items:
                          const [
                                '09:00 AM - 12:00 PM',
                                '01:00 PM - 03:00 PM',
                                '03:30 PM - 05:30 PM',
                              ]
                              .map(
                                (slot) => DropdownMenuItem(
                                  value: slot,
                                  child: Text(slot),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null)
                          setDialogState(() => selectedSlot = value);
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.tryParse(selectedDate) ??
                                DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setDialogState(
                              () => selectedDate =
                                  '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
                            );
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text('Date: $selectedDate'),
                      ),
                    ),
                    TextField(
                      scrollPadding: const EdgeInsets.only(bottom: 140),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        labelText: 'Find patient',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) =>
                          setDialogState(() => filter = value.trim()),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Queue is populated from confirmed appointments; patient selection is read-only.',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: availablePatients.isEmpty
                          ? const Center(
                              child: Text('No patients found in Firestore.'),
                            )
                          : ListView.builder(
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final patient = filtered[index];
                                final id = patient['id'].toString();
                                return CheckboxListTile(
                                  dense: true,
                                  value: selected.contains(id),
                                  title: Text(patient['name'].toString()),
                                  subtitle: Text(
                                    '${patient['nic']} · ${patient['phone']}',
                                  ),
                                  onChanged: null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                  ),
                  onPressed:
                      (session != null &&
                          selectedSlot == initialSlot &&
                          selectedDate == initialDate)
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          await _saveSession(
                            session: session,
                            doctorId: doctor.uid,
                            doctorName:
                                doctor.displayName ?? doctor.email ?? 'Doctor',
                            timeSlot: selectedSlot,
                            slotDate: selectedDate,
                            patients: null,
                          );
                        },
                  child: Text(
                    session == null ? 'Create session' : 'Save changes',
                  ),
                ),
              ],
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
                      color: _bg,
                      borderRadius: BorderRadius.circular(14),
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

  // ---- Shared decoration helper (pure styling) ----
  BoxDecoration _cardDecoration({double radius = 18}) => BoxDecoration(
    color: _surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _border),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF0F172A).withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}