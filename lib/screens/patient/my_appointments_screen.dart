import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/patient_service.dart';
import 'cancel_appointment_screen.dart';
import 'live_queue_tracker_screen.dart';
import 'reschedule_appointment_screen.dart';
import 'visit_summary_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final PatientService _patientService = PatientService();
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ===== CUSTOM HEADER =====
            _buildCustomHeader(),

            // ===== CONTENT =====
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _selectedTab == 0
                    ? _patientService.getUpcomingAppointments()
                    : _patientService.getPastVisits(),
                builder: (context, snapshot) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ===== TABS =====
                        _buildTabs(),
                        const SizedBox(height: 20),

                        // ===== SECTION TITLE =====
                        _sectionHeader(),

                        const SizedBox(height: 12),

                        // ===== CONTENT BY STATE =====
                        if (snapshot.connectionState ==
                            ConnectionState.waiting)
                          _buildLoadingState()
                        else if (snapshot.hasError)
                          _errorState(snapshot.error)
                        else if ((snapshot.data ?? []).isEmpty)
                          _emptyState()
                        else if (_selectedTab == 0)
                          _upcomingContent(snapshot.data!)
                        else
                          _pastContent(snapshot.data!),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey.shade400,
        selectedLabelStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_rounded),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CUSTOM HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildCustomHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Title block
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Appointments',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Government Hospital OPD',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Settings icon
          InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.settings_outlined,
                size: 18,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TABS
  // ═══════════════════════════════════════════════════════════
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _tabItem(
            icon: Icons.calendar_month_rounded,
            label: 'Upcoming',
            index: 0,
          ),
          _tabItem(
            icon: Icons.history_rounded,
            label: 'Past Visits',
            index: 1,
          ),
        ],
      ),
    );
  }

  Widget _tabItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  SECTION HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _sectionHeader() {
    final isUpcoming = _selectedTab == 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isUpcoming
                ? const Color(0xFFEFF6FF)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isUpcoming
                ? Icons.event_note_rounded
                : Icons.folder_open_rounded,
            size: 14,
            color: isUpcoming ? const Color(0xFF3B82F6) : Colors.grey.shade700,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          isUpcoming ? "TODAY'S & FUTURE SESSIONS" : 'PAST VISITS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isUpcoming ? const Color(0xFF3B82F6) : Colors.grey.shade700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  LOADING STATE
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              color: Color(0xFF3B82F6),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Loading appointments...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  UPCOMING CONTENT
  // ═══════════════════════════════════════════════════════════
  Widget _upcomingContent(List<Map<String, dynamic>> appointments) {
    final sorted = [...appointments]
      ..sort((a, b) => _appointmentDate(a).compareTo(_appointmentDate(b)));
    final today = DateTime.now();
    final todayAppointments = sorted
        .where((appointment) => _isSameDay(_appointmentDate(appointment), today))
        .toList();
    final futureAppointments = sorted
        .where((appointment) => !_isSameDay(_appointmentDate(appointment), today))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayAppointments.isNotEmpty) ...[
          _sectionTitle("TODAY'S SESSIONS", todayAppointments.length,
              const Color(0xFF3B82F6)),
          ...todayAppointments.map((appointment) => _upcomingCard(appointment)),
          if (futureAppointments.isNotEmpty) const SizedBox(height: 12),
        ],
        if (futureAppointments.isNotEmpty) ...[
          _sectionTitle('FUTURE SESSIONS', futureAppointments.length,
              Colors.grey.shade700),
          ...futureAppointments.map((appointment) => _upcomingCard(appointment)),
        ],
      ],
    );
  }

  Widget _sectionTitle(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _upcomingCard(Map<String, dynamic> appointment) {
    final date = _appointmentDate(appointment);
    final isToday = _isSameDay(date, DateTime.now());
    final id = appointment['id']?.toString();
    final doctor = _textOrFallback(appointment['doctorName'], 'OPD Doctor');
    final department = _textOrFallback(appointment['department'], 'OPD');
    final hospital =
        _textOrFallback(appointment['hospital'], 'Government Hospital');
    final token = _textOrFallback(
      appointment['tokenNumber'] ?? appointment['token'],
      'T-000',
    );
    final time = _textOrFallback(appointment['appointmentTime'], 'Time not set');
    final dateText = DateFormat('EEE, d MMM yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isToday
                ? const Color(0xFF3B82F6).withOpacity(0.25)
                : Colors.grey.shade200,
            width: isToday ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isToday
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : Colors.grey.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // ===== HEADER ROW =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isToday
                          ? const Color(0xFFDBEAFE)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isToday ? 'TODAY' : 'CONFIRMED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isToday
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF059669),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _tokenPill(token),
                ],
              ),
            ),

            // ===== DOCTOR INFO =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF3B82F6).withOpacity(0.15),
                          const Color(0xFF3B82F6).withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Color(0xFF3B82F6),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doctor,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.medical_services_outlined,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                department,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.local_hospital_outlined,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hospital,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
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
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ===== DATE / TIME STRIP =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 14, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 16,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ===== REFERENCE NUMBER =====
            if (appointment['referenceNumber'] != null &&
                appointment['referenceNumber'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      appointment['referenceNumber'].toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // ===== ACTION BUTTONS =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        if (id == null) return;
                        if (isToday) {
                          _openReschedule(appointment, dateTime: dateText);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CancelAppointmentScreen(
                                appointmentId: id,
                                doctorName: doctor,
                                department: department,
                                token: token,
                                dateTime: '$dateText • $time',
                              ),
                            ),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        foregroundColor: Colors.black87,
                      ),
                      child: Text(
                        isToday ? 'Reschedule' : 'Cancel Booking',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (id == null) return;
                        if (isToday) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LiveQueueTrackerScreen(appointmentId: id),
                            ),
                          );
                        } else {
                          _openReschedule(
                            appointment,
                            dateTime: dateText,
                            isReschedule: false,
                          );
                        }
                      },
                      icon: Icon(
                        isToday
                            ? Icons.play_circle_outline_rounded
                            : Icons.edit_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: Text(
                        isToday ? 'Track Queue' : 'Modify',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PAST CONTENT
  // ═══════════════════════════════════════════════════════════
  Widget _pastContent(List<Map<String, dynamic>> visits) {
    return Column(
      children: visits
          .map(
            (visit) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _pastVisitCard(visit),
            ),
          )
          .toList(),
    );
  }

  Widget _pastVisitCard(Map<String, dynamic> record) {
    final formattedDate = _formatPastDate(record['date']);
    final token = _textOrFallback(record['tokenNo'], 'T-000');
    final diagnosis = record['diagnosis']?.toString();
    final prescription = record['prescription']?.toString();
    final advice = record['advice']?.toString();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.15),
                        const Color(0xFF10B981).withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate == 'Date not available'
                            ? 'Past Visit'
                            : 'Visit on ${formattedDate.split(' • ').first}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'COMPLETED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _tokenPill(token),
              ],
            ),
          ),

          // ===== DATE STRIP =====
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 14, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      formattedDate,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ===== DETAILS =====
          if (_hasText(diagnosis)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _sectionBlock(
                icon: Icons.medical_information_outlined,
                iconColor: const Color(0xFFEF4444),
                title: 'DIAGNOSIS',
                child: Text(
                  diagnosis!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_hasText(prescription)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _infoBlock(
                icon: Icons.medication_outlined,
                iconColor: const Color(0xFF10B981),
                title: 'PRESCRIPTION',
                value: prescription!,
                bgColor: const Color(0xFFF0FDF4),
                borderColor: const Color(0xFF10B981),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (_hasText(advice)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _infoBlock(
                icon: Icons.lightbulb_outline_rounded,
                iconColor: const Color(0xFFD97706),
                title: 'ADVICE',
                value: advice!,
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFD97706),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 14),

          // ===== ACTIONS =====
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RescheduleAppointmentScreen(
                          doctorName: 'OPD Doctor',
                          department: 'OPD',
                          hospital: 'Government Hospital',
                          token: 'New',
                          dateTime: 'Not scheduled',
                          isReschedule: false,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded,
                        size: 16, color: Colors.black87),
                    label: const Text(
                      'Book Again',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VisitSummaryScreen(
                          doctorName: 'OPD Doctor',
                          department: 'OPD',
                          hospital: 'Government Hospital',
                          token: token,
                          dateTime: formattedDate,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.description_outlined,
                        size: 16, color: Colors.white),
                    label: const Text(
                      'View Summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

  // ═══════════════════════════════════════════════════════════
  //  REUSABLE UI ELEMENTS
  // ═══════════════════════════════════════════════════════════
  Widget _sectionBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: iconColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _infoBlock({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tokenPill(String token) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_outlined,
              size: 11, color: Color(0xFF1E40AF)),
          const SizedBox(width: 4),
          Text(
            token,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorState(Object? error) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _selectedTab == 0
                ? 'Could not load your appointments'
                : 'Could not load your visit history',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final past = _selectedTab == 1;
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: past ? Colors.grey.shade100 : const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              past ? Icons.history_rounded : Icons.event_available_rounded,
              size: 44,
              color: past ? Colors.grey.shade400 : const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            past ? 'No Past Visits Yet' : 'No Upcoming Appointments',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            past
                ? 'Your completed appointments will appear here once you have visited the hospital.'
                : 'Your confirmed appointments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _openReschedule(
    Map<String, dynamic> appointment, {
    required String dateTime,
    bool isReschedule = true,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RescheduleAppointmentScreen(
          appointmentId: appointment['id']?.toString(),
          doctorName: _textOrFallback(appointment['doctorName'], 'OPD Doctor'),
          department: _textOrFallback(appointment['department'], 'OPD'),
          hospital: _textOrFallback(
            appointment['hospital'],
            'Government Hospital',
          ),
          token: _textOrFallback(
            appointment['tokenNumber'] ?? appointment['token'],
            'T-000',
          ),
          dateTime: dateTime,
          isReschedule: isReschedule,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  DATA HELPERS (UNCHANGED)
  // ═══════════════════════════════════════════════════════════
  DateTime _appointmentDate(Map<String, dynamic> appointment) {
    final raw = appointment['appointmentDate'] ?? appointment['dateTime'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw?.toString() ?? '') ?? DateTime.now();
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _formatPastDate(dynamic raw) {
    final date = _parseDate(raw);
    if (date == null) return 'Date not available';
    return DateFormat('EEE, d MMM yyyy • h:mm a').format(date);
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _textOrFallback(dynamic value, String fallback) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }
}