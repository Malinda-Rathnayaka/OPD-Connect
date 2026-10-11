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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Appointments',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
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
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _tabButton('Upcoming', 0),
                        _tabButton('Past Visits', 1),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _selectedTab == 0
                        ? "TODAY'S & FUTURE SESSIONS"
                        : 'PAST VISITS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _selectedTab == 0 ? Colors.blue : Colors.grey,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Center(child: CircularProgressIndicator())
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

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
          _sectionTitle("TODAY'S SESSIONS"),
          ...todayAppointments.map((appointment) => _upcomingCard(appointment)),
        ],
        if (futureAppointments.isNotEmpty) ...[
          _sectionTitle('FUTURE SESSIONS'),
          ...futureAppointments.map((appointment) => _upcomingCard(appointment)),
        ],
      ],
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
      child: _appointmentCard(
        doctorName: doctor,
        department: department,
        hospital: hospital,
        token: token,
        dateTime: '$dateText • $time',
        referenceNumber: appointment['referenceNumber']?.toString(),
        primaryButton: isToday ? 'Track Queue' : 'Modify',
        secondaryButton: isToday ? 'Reschedule' : 'Cancel Booking',
        onPrimary: () {
          if (isToday && id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LiveQueueTrackerScreen(appointmentId: id),
              ),
            );
          } else if (id != null) {
            _openReschedule(
              appointment,
              dateTime: dateText,
              isReschedule: false,
            );
          }
        },
        onSecondary: () {
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
        overflow: !isToday && id != null
            ? () => _openReschedule(appointment, dateTime: dateText)
            : null,
      ),
    );
  }

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

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  formattedDate == 'Date not available'
                      ? 'Past Visit'
                      : 'Visit on ${formattedDate.split(' • ').first}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _tokenPill(token),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(formattedDate),
            ],
          ),
          const Divider(height: 24),
          if (_hasText(diagnosis)) _detail('Diagnosis', diagnosis!),
          if (_hasText(prescription))
            _infoDetail('Prescription', prescription!, const Color(0xFFEFF6FF)),
          if (_hasText(advice)) _infoDetail('Advice', advice!, Colors.grey.shade50),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
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
                  style: _primaryButtonStyle(),
                  child: const Text('View Summary'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
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
                  child: const Text('Book Again'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _appointmentCard({
    required String doctorName,
    required String department,
    required String hospital,
    required String token,
    required String dateTime,
    required String primaryButton,
    required String secondaryButton,
    String? referenceNumber,
    required VoidCallback onPrimary,
    required VoidCallback onSecondary,
    VoidCallback? overflow,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doctorName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              _tokenPill(token),
              if (overflow != null)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (_) => overflow(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'reschedule',
                      child: Text('Reschedule'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(department, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 2),
          Text(hospital, style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(child: Text(dateTime)),
            ],
          ),
          if (referenceNumber != null) ...[
            const SizedBox(height: 6),
            Text(
              referenceNumber,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSecondary,
                  child: Text(secondaryButton),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrimary,
                  style: _primaryButtonStyle(),
                  child: Text(primaryButton),
                ),
              ),
            ],
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3B82F6),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _errorState(Object? error) {
    return _card(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(
            _selectedTab == 0
                ? 'Could not load your appointments'
                : 'Could not load your visit history',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: _primaryButtonStyle(),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    final past = _selectedTab == 1;
    return _card(
      padding: 40,
      child: Column(
        children: [
          Icon(
            past ? Icons.history : Icons.event_busy,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            past ? 'No Past Visits Yet' : 'No Upcoming Appointments',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            past
                ? 'Your completed appointments will appear here once you have visited the hospital.'
                : 'Your confirmed appointments will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child, double padding = 16}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _tokenPill(String token) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        token,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1E40AF),
        ),
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  Widget _infoDetail(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    );
  }

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
