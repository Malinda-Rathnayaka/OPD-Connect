import 'package:flutter/material.dart';
import 'department_select.dart';
import 'patient_home_screen.dart';
import 'doctor_availability.dart';
import 'my_family_profile.dart';
import 'booking_confirmed.dart';

class ReviewConfirmBookingScreen extends StatefulWidget {
  final String hospitalId;
  final String hospitalName;
  final String doctorId;
  final String doctorName;
  final String department;
  final String sessionId;
  final DateTime date;
  final String time;
  final int slotNumber;
  final String patientName;
  final String bookingFor;

  const ReviewConfirmBookingScreen({
    super.key,
    required this.hospitalId,
    required this.hospitalName,
    required this.doctorId,
    required this.doctorName,
    required this.department,
    required this.sessionId,
    required this.date,
    required this.time,
    required this.slotNumber,
    this.patientName = 'Kamal Perera',
    this.bookingFor = 'Myself',
  });

  @override
  State<ReviewConfirmBookingScreen> createState() => _ReviewConfirmBookingScreenState();
}

class _ReviewConfirmBookingScreenState extends State<ReviewConfirmBookingScreen> {
  bool _agreedToGuidelines = false;

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
      'Dec'
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Review & Confirm Booking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Appointment Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(
                      label: 'Patient',
                      value: '${widget.patientName} (${widget.bookingFor})',
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Hospital',
                      value: widget.hospitalName,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Department',
                      value: widget.department,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Doctor',
                      value: widget.doctorName,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Session ID',
                      value: widget.sessionId,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Date & Time',
                      value: '${_formatDate(widget.date)} @ ${widget.time} (Slot #${widget.slotNumber})',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: CheckboxListTile(
                value: _agreedToGuidelines,
                onChanged: (value) {
                  setState(() {
                    _agreedToGuidelines = value ?? false;
                  });
                },
                activeColor: Colors.blue,
                contentPadding: const EdgeInsets.all(16),
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I agree to the National Hospital OPD guidelines and consent to receive digital queue token updates.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreedToGuidelines
                    ? () {
                        final referenceNumber =
                            'OPD-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch % 100000}';

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingConfirmedScreen(
                              hospitalName: widget.hospitalName,
                              department: widget.department,
                              doctorName: widget.doctorName,
                              date: widget.date,
                              time: widget.time,
                              tokenNumber: widget.slotNumber,
                              referenceNumber: referenceNumber,
                              patientName: widget.patientName,
                              bookingFor: widget.bookingFor,
                              sessionId: widget.sessionId,
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue.shade200,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Confirm & Get Token'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Discard Booking'),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 2,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientHomeScreen(),
                ),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DepartmentSelectScreen(),
                ),
              );
              break;
            case 2:
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyFamilyProfileScreen(),
                ),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DoctorAvailabilityScreen(
                    hospitalId: widget.hospitalId,
                    hospitalName: widget.hospitalName,
                    department: widget.department,
                  ),
                ),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_outlined),
            label: 'Queue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () {},
          child: const Text('Change'),
        ),
      ],
    );
  }
}
