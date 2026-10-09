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

  // ---- Modern theme tokens ----
  static const _bg = Color(0xFFF4F6FB);
  static const _primary = Color(
    0xFF3B82F6,
  ); // <-- updated button / accent color
  static const _primaryDark = Color(0xFF2563EB);
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
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: _surface,
          elevation: 0,
          height: 68,
          indicatorColor: _primary.withOpacity(0.12),
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) =>
              setState(() => _selectedIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: _primary),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.queue_outlined),
              selectedIcon: Icon(Icons.queue, color: _primary),
              label: 'Live Queue',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: _primary),
              label: 'Records',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: _primary),
              label: 'Profile',
            ),
          ],
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
            backgroundColor: _primary, // #3B82F6
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _isSavingSession ? null : () => _showSessionDialog(),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Slot'),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _welcomeCard(),
            const SizedBox(height: 20),
            _summaryCards(todayActive),
            const SizedBox(height: 28),
            _todayAppointmentsCard(),
            const SizedBox(height: 20),
            Card(
              elevation: 0,
              color: const Color(0xFFF5F3FF),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF7C3AED),
                  child: Icon(Icons.event_available, color: Colors.white),
                ),
                title: const Text(
                  'Manage Availability & Leaves',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Submit and track leave requests'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DoctorLeaveScreen()),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
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
                const Text(
                  'Sessions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: sessions.map(_openQueueCard).toList(),
        );
      },
    ),
  );

  Widget _todayAppointmentsCard() => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
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
              const Text(
                "Today's booked appointments",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (appointments.isEmpty)
                const Text(
                  'No appointments for today. Start a session after patients book a slot.',
                  style: TextStyle(color: _muted),
                )
              else
                ...appointments
                    .take(4)
                    .map(
                      (doc) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(
                          Icons.event_available,
                          color: _primary,
                        ),
                        title: Text(
                          doc.data()['patientName']?.toString() ?? 'Patient',
                        ),
                        subtitle: Text(
                          '${doc.data()['appointmentTime'] ?? 'Time not set'} · '
                          'Token ${doc.data()['tokenNumber'] ?? 'Not assigned'}',
                        ),
                      ),
                    ),
            ],
          );
        },
      ),
    ),
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
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: sessions.map((session) {
            final data = session.data();
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.getCompletedRecords(session.id),
              builder: (context, records) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: _cardDecoration(),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_copy_outlined,
                      color: _accent,
                    ),
                  ),
                  title: Text(
                    '${data['slotDate'] ?? ''} · ${data['timeSlot'] ?? 'OPD Session'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${records.data?.docs.length ?? 0} patients treated',
                      style: const TextStyle(color: _muted),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: _muted),
                  onTap: () => _showRecords(
                    session.id,
                    data['timeSlot']?.toString() ?? 'Session',
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
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          color: _ink,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: -0.4,
        ),
      ),
      actions: [
        ...?actions,
        IconButton(
          tooltip: 'Sign out',
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout_outlined),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: child,
  );

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access the doctor dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout),
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
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dr. ${user?.displayName ?? user?.email ?? 'Doctor'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
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
            Icons.hourglass_bottom,
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
              Icons.hourglass_bottom,
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: _cardDecoration(radius: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: _muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
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
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openLiveQueue(session.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
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
                        ),
                        const SizedBox(height: 6),
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
                    icon: const Icon(Icons.more_vert, color: _muted),
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
        );
      },
    );
  }

  Widget _statusPill(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
            title: const Text('Delete session?'),
            content: const Text(
              'This removes the session queue and its session records. Patient medical histories are retained.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _primary),
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
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.play_circle_outline, color: Color(0xFF10B981)),
      ),
      title: Text(
        doc.data()['timeSlot']?.toString() ?? 'OPD Session',
        style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          doc.data()['slotDate']?.toString() ?? '',
          style: const TextStyle(color: _muted),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.arrow_forward, color: _primary, size: 18),
      ),
      onTap: () => _openLiveQueue(doc.id),
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
                  style: FilledButton.styleFrom(backgroundColor: _primary),
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
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
