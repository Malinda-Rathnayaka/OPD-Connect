import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'booking_confirmed.dart';
import 'my_family_profile.dart';
import 'patient_home_screen.dart';

class ReviewConfirmBookingScreen extends StatefulWidget {
  final String sessionId;
  final String time;
  final DateTime appointmentDate;
  final String bookingForId;
  final String bookingForName;

  const ReviewConfirmBookingScreen({
    super.key,
    required this.sessionId,
    required this.time,
    required this.appointmentDate,
    required this.bookingForId,
    required this.bookingForName,
  });

  @override
  State<ReviewConfirmBookingScreen> createState() =>
      _ReviewConfirmBookingScreenState();
}

class _ReviewConfirmBookingScreenState
    extends State<ReviewConfirmBookingScreen> {
  bool _agreedToGuidelines = false;
  bool _isSubmitting = false;
  bool _isLoadingBookingData = true;
  String? _bookingDataError;
  String _patientName = '';
  String _accountName = '';
  int _currentAvailableSlots = 0;
  int _totalSlots = 0;

  @override
  void initState() {
    super.initState();
    _loadBookingData();
  }

  DateTime? _parseSessionDate(dynamic value) {
    if (value is Timestamp) return DateUtils.dateOnly(value.toDate());
    if (value is DateTime) return DateUtils.dateOnly(value);
    if (value is! String || value.trim().isEmpty) return null;
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return DateUtils.dateOnly(parsed);
    for (final format in [
      DateFormat('EEE, d MMM yyyy', 'en_US'),
      DateFormat('EEE, d MMM', 'en_US'),
    ]) {
      try {
        return DateUtils.dateOnly(format.parseStrict(value.trim()));
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  Future<void> _loadBookingData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _bookingDataError = 'Please sign in before booking an appointment.';
        _isLoadingBookingData = false;
      });
      return;
    }
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      final accountName = userDoc.data()?['name']?.toString().trim() ?? '';
      if (!userDoc.exists || accountName.isEmpty) {
        throw StateError(
          'Your account name is missing from your user profile.',
        );
      }

      final sessionDoc = await firestore
          .collection('sessions')
          .doc(widget.sessionId)
          .get();
      if (!sessionDoc.exists) {
        throw StateError('The selected session is no longer available.');
      }
      final sessionData = sessionDoc.data() ?? {};
      final available = (sessionData['availableSlots'] as num?)?.toInt() ?? 0;
      if (available <= 0) {
        throw StateError(
          'This session is fully booked. Please choose another session.',
        );
      }
      final storedDate = _parseSessionDate(sessionData['date']);
      if (storedDate == null ||
          !DateUtils.isSameDay(storedDate, widget.appointmentDate) ||
          !storedDate.isAfter(DateUtils.dateOnly(DateTime.now()))) {
        throw StateError(
          'The selected session date has changed. Please choose a session again.',
        );
      }

      final patientName = widget.bookingForId == currentUser.uid
          ? accountName
          : widget.bookingForName.trim();
      if (patientName.isEmpty) {
        throw StateError('The selected patient name is unavailable.');
      }
      final totalSlots =
          (sessionData['totalSlots'] as num?)?.toInt() ?? available;
      if (!mounted) return;
      setState(() {
        _accountName = accountName;
        _patientName = patientName;
        _currentAvailableSlots = available;
        _totalSlots = totalSlots;
        _isLoadingBookingData = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _bookingDataError = error.toString().replaceFirst('Bad state: ', '');
        _isLoadingBookingData = false;
      });
    }
  }

  String get _tokenNumber {
    final nextToken = (_totalSlots - _currentAvailableSlots + 1).clamp(1, 999);
    return 'T-${nextToken.toString().padLeft(3, '0')}';
  }

  void _navigateToSlotSelection() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _confirmBooking() async {
    if (!_agreedToGuidelines) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please agree to the OPD guidelines before continuing.',
          ),
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before booking an appointment.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final sessionRef = firestore.collection('sessions').doc(widget.sessionId);
      final userRef = firestore.collection('users').doc(currentUser.uid);
      final appointmentRef = firestore.collection('appointments').doc();
      late String tokenNumber;
      final bookingDate = DateUtils.dateOnly(widget.appointmentDate);

      await firestore.runTransaction((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final sessionSnapshot = await transaction.get(sessionRef);
        if (!userSnapshot.exists || !sessionSnapshot.exists) {
          throw StateError('The selected booking data is no longer available.');
        }

        final accountName =
            userSnapshot.data()?['name']?.toString().trim() ?? '';
        if (accountName.isEmpty || accountName != _accountName) {
          throw StateError(
            'Your account name could not be verified. Please reload and try again.',
          );
        }

        final sessionData = sessionSnapshot.data() ?? {};
        final sessionDate = _parseSessionDate(sessionData['date']);
        if (sessionDate == null ||
            !DateUtils.isSameDay(sessionDate, bookingDate) ||
            !sessionDate.isAfter(DateUtils.dateOnly(DateTime.now()))) {
          throw StateError(
            'This session date is no longer available. Please choose another session.',
          );
        }
        final currentAvailableSlots =
            (sessionData['availableSlots'] as num?)?.toInt() ?? 0;
        if (currentAvailableSlots <= 0) {
          throw StateError(
            'This session is fully booked. Please choose another session.',
          );
        }
        final totalSlots =
            (sessionData['totalSlots'] as num?)?.toInt() ??
            currentAvailableSlots;
        final tokenIndex = (totalSlots - currentAvailableSlots + 1).clamp(
          1,
          999,
        );
        tokenNumber = 'T-${tokenIndex.toString().padLeft(3, '0')}';

        transaction.set(appointmentRef, {
          'patientId': currentUser.uid,
          'patientName': _patientName,
          'bookedForId': widget.bookingForId,
          'bookedForName': _patientName,
          'bookedById': currentUser.uid,
          'bookedByName': accountName,
          'sessionId': widget.sessionId,
          'appointmentDate': Timestamp.fromDate(bookingDate),
          'appointmentTime': widget.time,
          'tokenNumber': tokenNumber,
          'referenceNumber': appointmentRef.id,
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(sessionRef, {
          'availableSlots': currentAvailableSlots - 1,
          'totalSlots': totalSlots,
          'isAvailable': currentAvailableSlots - 1 > 0,
        });
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmedScreen(
            patientName: _patientName,
            date: DateFormat('EEE, d MMM yyyy').format(bookingDate),
            time: widget.time,
            tokenNumber: tokenNumber,
            referenceNumber: appointmentRef.id,
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
      body: _isLoadingBookingData
          ? const Center(child: CircularProgressIndicator())
          : _bookingDataError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(_bookingDataError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _navigateToSlotSelection,
                      child: const Text('Choose another session'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Appointment Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _navigateToSlotSelection,
                                icon: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  'Change',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _DetailRow(label: 'Patient', value: _patientName),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Date',
                            value: DateFormat('EEE, d MMM yyyy')
                                .format(widget.appointmentDate),
                          ),
                          const SizedBox(height: 12),
                          _DetailRow(label: 'Time', value: widget.time),
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: 'Token Number',
                            value: _tokenNumber,
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
                      onPressed:
                          _isSubmitting ||
                              _isLoadingBookingData ||
                              _bookingDataError != null
                          ? null
                          : _confirmBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.blue.shade200,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
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
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => const PatientHomeScreen(),
                ),
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
                MaterialPageRoute(
                  builder: (context) => const MyFamilyProfileScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.queue_outlined),
            label: 'Queue',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
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
