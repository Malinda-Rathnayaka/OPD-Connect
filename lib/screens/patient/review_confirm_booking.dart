import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_confirmed.dart';
import 'my_family_profile.dart';
import 'patient_home_screen.dart';
import 'select_appointment_slot.dart';

class ReviewConfirmBookingScreen extends StatefulWidget {
  final String sessionId;
  final String doctorId;
  final String time;
  final String date;
  final int availableSlots;

  const ReviewConfirmBookingScreen({
    super.key,
    required this.sessionId,
    required this.doctorId,
    required this.time,
    required this.date,
    required this.availableSlots,
  });

  @override
  State<ReviewConfirmBookingScreen> createState() => _ReviewConfirmBookingScreenState();
}

class _ReviewConfirmBookingScreenState extends State<ReviewConfirmBookingScreen> {
  bool _agreedToGuidelines = false;
  bool _isSubmitting = false;
  String _patientName = 'Patient';
  String _doctorName = 'Doctor';
  String _department = 'General Medicine';
  String _hospitalName = 'Colombo National Hospital';
  String _hospitalId = 'colombo-national';

  @override
  void initState() {
    super.initState();
    _doctorName = widget.doctorId.isNotEmpty ? widget.doctorId : 'Doctor';
    _loadLoggedInUser();
    _loadDoctorInfo();
  }

  Future<void> _loadLoggedInUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _patientName = 'Patient';
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final name = userDoc.data()?['name']?.toString().trim();
      setState(() {
        _patientName = name != null && name.isNotEmpty ? name : 'Patient';
      });
    } catch (error) {
      debugPrint('DEBUG: failed to load user data: $error');
      setState(() {
        _patientName = currentUser.displayName ?? currentUser.email?.split('@').first ?? 'Patient';
      });
    }
  }

  Future<void> _loadDoctorInfo() async {
    if (widget.doctorId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _doctorName = data['fullName']?.toString() ?? widget.doctorId;
          _department = data['department']?.toString() ?? 'General Medicine';
          _hospitalName = data['hospitalName']?.toString() ?? 'Colombo National Hospital';
          _hospitalId = data['hospitalId']?.toString() ?? 'colombo-national';
        });
      }
    } catch (e) {
      debugPrint('DEBUG: Error loading doctor info: $e');
    }
  }

  void _navigateToSlotSelection() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SelectAppointmentSlotScreen(),
        ),
      );
    }
  }

  Future<void> _confirmBooking() async {
    if (!_agreedToGuidelines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the OPD guidelines before continuing.')),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before booking an appointment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final sessionRef = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);
      final sessionSnapshot = await sessionRef.get();

      if (!sessionSnapshot.exists) {
        throw Exception('Selected session was not found.');
      }

      final sessionData = sessionSnapshot.data() ?? {};
      final currentAvailableSlots = (sessionData['availableSlots'] as num?)?.toInt() ?? 0;

      if (currentAvailableSlots <= 0) {
        throw Exception('This session is fully booked. Please choose another session.');
      }

      final referenceNumber = 'OPD-${DateTime.now().millisecondsSinceEpoch}';
      final tokenNumber = 'T-${currentAvailableSlots.toString().padLeft(3, '0')}';

      await FirebaseFirestore.instance.collection('appointments').add({
        'patientId': currentUser.uid,
        'patientName': _patientName,
        'hospitalId': _hospitalId,
        'hospitalName': _hospitalName,
        'doctorId': widget.doctorId,
        'doctorName': _doctorName,
        'department': _department,
        'sessionId': widget.sessionId,
        'appointmentDate': widget.date,
        'appointmentTime': widget.time,
        'sessionType': 'General',
        'tokenNumber': tokenNumber,
        'status': 'confirmed',
        'referenceNumber': referenceNumber,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await sessionRef.update({
        'availableSlots': FieldValue.increment(-1),
        'isAvailable': (currentAvailableSlots - 1) > 0,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment confirmed successfully')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmedScreen(
            patientName: _patientName,
            date: widget.date,
            time: widget.time,
            tokenNumber: tokenNumber,
            referenceNumber: referenceNumber,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to confirm booking: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _discardBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Booking?'),
        content: const Text('Your current booking details will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.pop(context);
    }
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Appointment Details',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        TextButton.icon(
                          onPressed: _navigateToSlotSelection,
                          icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                          label: const Text(
                            'Change',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _DetailRow(label: 'Patient Name', value: _patientName),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Date', value: widget.date),
                    const SizedBox(height: 12),
                    _DetailRow(label: 'Time', value: widget.time),
                    const SizedBox(height: 12),
                    const _DetailRow(label: 'Token Number', value: 'Generated upon confirmation'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.blue.shade200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Confirm & Get Token'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _discardBooking,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PatientHomeScreen()),
                (route) => false,
              );
              break;
            case 1:
            case 3:
              _navigateToSlotSelection();
              break;
            case 2:
            case 4:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyFamilyProfileScreen()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.queue_outlined), label: 'Queue'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
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
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
