import 'package:flutter/material.dart';
import 'live_queue_tracker_screen.dart';
import 'cancel_appointment_screen.dart';
import 'reschedule_appointment_screen.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  int _selectedTab = 0; // 0 = Upcoming, 1 = Past Visits

  // ===== UPCOMING APPOINTMENTS DATA =====
  final List<Map<String, dynamic>> _upcomingAppointments = [
    {
      'doctorName': 'Dr. Kamal Perera',
      'department': 'General Medicine • CGH Room 4',
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
      'token': 'T-029',
      'dateTime': 'Wed, 24 Sep • 2:00 PM',
      'badgeText': null,
      'badgeColor': null,
      'primaryButton': 'Modify',
      'secondaryButton': 'Cancel Booking',
      'isToday': false,
    },
  ];

  // ===== PAST VISITS DATA =====
  final List<Map<String, dynamic>> _pastAppointments = [
    {
      'doctorName': 'Dr. Kamal Perera',
      'department': 'General Medicine • CGH Room 4',
      'token': 'T-008',
      'dateTime': 'Mon, 15 Sep • 9:00 AM',
      'badgeText': 'Completed',
      'badgeColor': Colors.green,
      'primaryButton': 'View Summary',
      'secondaryButton': 'Book Again',
      'isToday': false,
    },
    {
      'doctorName': 'Dr. Anura Wijesinghe',
      'department': 'Eye Clinic • Colombo General',
      'token': 'T-022',
      'dateTime': 'Fri, 5 Sep • 11:00 AM',
      'badgeText': 'Completed',
      'badgeColor': Colors.green,
      'primaryButton': 'View Summary',
      'secondaryButton': 'Book Again',
      'isToday': false,
    },
    {
      'doctorName': 'Dr. Nimal Sirisena',
      'department': 'Cardiology • CGH Room 2',
      'token': 'T-005',
      'dateTime': 'Tue, 26 Aug • 10:00 AM',
      'badgeText': 'Completed',
      'badgeColor': Colors.green,
      'primaryButton': 'View Summary',
      'secondaryButton': 'Book Again',
      'isToday': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Tab එකට අනුව data තෝරන්න
    final appointments =
        _selectedTab == 0 ? _upcomingAppointments : _pastAppointments;

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
              // ===== TAB SWITCHER =====
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    _tabButton('Upcoming (${_upcomingAppointments.length})', 0),
                    _tabButton('Past Visits (${_pastAppointments.length})', 1),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ===== SECTION HEADER =====
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

              // ===== APPOINTMENT LIST =====
              if (appointments.isEmpty)
                _emptyState()
              else
                ...appointments.map((appointment) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _appointmentCard(
                      context: context,
                      doctorName: appointment['doctorName'],
                      department: appointment['department'],
                      token: appointment['token'],
                      dateTime: appointment['dateTime'],
                      badgeText: appointment['badgeText'],
                      badgeColor: appointment['badgeColor'],
                      primaryButton: appointment['primaryButton'],
                      secondaryButton: appointment['secondaryButton'],
                      isToday: appointment['isToday'],
                    ),
                  );
                }).toList(),
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
              icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // ===== Empty State =====
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ===== Tab Button =====
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

  // ===== Appointment Card =====
  Widget _appointmentCard({
    required BuildContext context,
    required String doctorName,
    required String department,
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
          // Doctor name + Token
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
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            department,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // Date + Badge
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          // Buttons
          Row(
            children: [
              // ===== Secondary Button =====
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // ===== Reschedule / Cancel Booking / Book Again =====
                    if (secondaryButton == 'Reschedule') {
                      // Reschedule screen එකට යන්න
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescheduleAppointmentScreen(
                            doctorName: doctorName,
                            department: department,
                            token: token,
                            dateTime: dateTime,
                            isReschedule: true,
                          ),
                        ),
                      );
                    } else if (secondaryButton == 'Cancel Booking') {
                      // Cancel screen එකට යන්න
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
                      // TODO: Booking screen එකට යන්න
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
                      // Live Queue Tracker screen එකට යන්න
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveQueueTrackerScreen(),
                        ),
                      );
                    } else if (primaryButton == 'Modify') {
                      // Modify screen එකට යන්න
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RescheduleAppointmentScreen(
                            doctorName: doctorName,
                            department: department,
                            token: token,
                            dateTime: dateTime,
                            isReschedule: false, // Modify mode
                          ),
                        ),
                      );
                    } else if (primaryButton == 'View Summary') {
                      // TODO: Summary screen එකට යන්න
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