import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/patient_service.dart';
import 'live_queue_tracker_screen.dart';
import 'cancel_appointment_screen.dart';
import 'reschedule_appointment_screen.dart';
import 'visit_summary_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  int _selectedTab = 0;
  final PatientService _patientService = PatientService();

  // ===== UPCOMING APPOINTMENTS =====
  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'doctorName': 'Dr. Kamal Perera',
      'department': 'General Medicine • CGH Room 4',
      'hospital': 'Colombo General Hospital',
      'token': 'T-014',
      'dateTime': 'Today, 10:30 AM',
      'badgeText': '3 Patients Ahead',
      'badgeColor': Colors.orange,
      'primaryButton': 'Track Queue',
      'secondaryButton': 'Reschedule',
      'isToday': true,
    },
    {
      'doctorName': 'Dr. Nishantha Silva',
      'department': 'Dental Clinic • Sri Jayawardenepura',
      'hospital': 'Sri Jayawardenepura General Hospital',
      'token': 'T-029',
      'dateTime': 'Wed, 24 Sep • 2:00 PM',
      'badgeText': null,
      'badgeColor': null,
      'primaryButton': 'Modify',
      'secondaryButton': 'Cancel Booking',
      'isToday': false,
    },
  ];

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
        child: SingleChildScrollView(
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
                    _tabButton('Upcoming (${_upcomingAppointments.length})', 0),
                    _tabButton('Past Visits', 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                _selectedTab == 0 ? "TODAY'S & FUTURE SESSIONS" : 'PAST VISITS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _selectedTab == 0 ? Colors.blue : Colors.grey,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),

              if (_selectedTab == 0)
                if (_upcomingAppointments.isEmpty)
                  _emptyState()
                else
                  ..._upcomingAppointments.map((appointment) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _appointmentCard(
                        context: context,
                        doctorName: appointment['doctorName'],
                        department: appointment['department'],
                        hospital: appointment['hospital'],
                        token: appointment['token'],
                        dateTime: appointment['dateTime'],
                        badgeText: appointment['badgeText'],
                        badgeColor: appointment['badgeColor'],
                        primaryButton: appointment['primaryButton'],
                        secondaryButton: appointment['secondaryButton'],
                        isToday: appointment['isToday'],
                      ),
                    );
                  }).toList()
              else
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _patientService.getPastVisits(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _pastVisitError(snapshot.error);
                    }
                    final visits = snapshot.data ?? [];
                    if (visits.isEmpty) return _pastVisitEmptyState();
                    return Column(
                      children: visits
                          .map(
                            (visit) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _pastVisitCard(context, visit),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          }
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

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    try {
      return DateTime.parse(raw.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatPastDate(dynamic raw) {
    final date = _parseDate(raw);
    if (date == null) return 'Date not available';
    return DateFormat('EEE, d MMM yyyy • h:mm a').format(date);
  }

  Widget _pastVisitError(Object? error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
          const SizedBox(height: 12),
          const Text(
            'Could not load your visit history',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pastVisitEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No Past Visits Yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your completed appointments will appear here once you have visited the hospital.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pastVisitCard(BuildContext context, Map<String, dynamic> record) {
    final formattedDate = _formatPastDate(record['date']);
    final token = record['tokenNo']?.toString() ?? 'T-000';
    final diagnosis = record['diagnosis']?.toString();
    final prescription = record['prescription']?.toString();
    final advice = record['advice']?.toString();

    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          if (diagnosis != null && diagnosis.isNotEmpty) ...[
            _pastVisitLabel('Diagnosis'),
            const SizedBox(height: 4),
            Text(diagnosis, style: const TextStyle(fontSize: 13)),
          ],
          if (prescription != null && prescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            _pastVisitInfoBox(
              'Prescription',
              prescription,
              const Color(0xFFEFF6FF),
            ),
          ],
          if (advice != null && advice.isNotEmpty) ...[
            const SizedBox(height: 12),
            _pastVisitInfoBox('Advice', advice, Colors.grey.shade50),
          ],
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
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
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
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

  Widget _pastVisitLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _pastVisitInfoBox(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pastVisitLabel(label),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _selectedTab == 0
                ? 'No upcoming appointments'
                : 'No past visits yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedTab == 0
                ? 'Book a new appointment to get started'
                : 'Your visit history will appear here',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard({
    required BuildContext context,
    required String doctorName,
    required String department,
    required String hospital,
    required String token,
    required String dateTime,
    String? badgeText,
    Color? badgeColor,
    required String primaryButton,
    required String secondaryButton,
    required bool isToday,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? const Color(0xFF3B82F6) : Colors.grey.shade200,
          width: isToday ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            department,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 12,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hospital,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                dateTime,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (badgeText != null && badgeColor != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // ===== Secondary Button =====
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    if (secondaryButton == 'Reschedule') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescheduleAppointmentScreen(
                            doctorName: doctorName,
                            department: department,
                            hospital: hospital,
                            token: token,
                            dateTime: dateTime,
                            isReschedule: true,
                          ),
                        ),
                      );
                    } else if (secondaryButton == 'Cancel Booking') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CancelAppointmentScreen(
                            doctorName: doctorName,
                            department: department,
                            token: token,
                            dateTime: dateTime,
                          ),
                        ),
                      );
                    } else if (secondaryButton == 'Book Again') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescheduleAppointmentScreen(
                            doctorName: doctorName,
                            department: department,
                            hospital: hospital,
                            token: 'New',
                            dateTime: 'Not scheduled',
                            isReschedule: false,
                          ),
                        ),
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    secondaryButton,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ===== Primary Button =====
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (primaryButton == 'Track Queue') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveQueueTrackerScreen(),
                        ),
                      );
                    } else if (primaryButton == 'Modify') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescheduleAppointmentScreen(
                            doctorName: doctorName,
                            department: department,
                            hospital: hospital,
                            token: token,
                            dateTime: dateTime,
                            isReschedule: false,
                          ),
                        ),
                      );
                    } else if (primaryButton == 'View Summary') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisitSummaryScreen(
                            doctorName: doctorName,
                            department: department,
                            hospital: hospital,
                            token: token,
                            dateTime: dateTime,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    primaryButton,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
