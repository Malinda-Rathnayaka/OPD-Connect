import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'booking_confirmed.dart';

class ReviewConfirmBookingScreen extends StatefulWidget {
  final String sessionId;
  final String time;
  final int availableSlots;
  final String bookingForName;

  const ReviewConfirmBookingScreen({
    super.key,
    required this.sessionId,
    required this.time,
    required this.availableSlots,
    required this.bookingForName,
  });

  @override
  State<ReviewConfirmBookingScreen> createState() =>
      _ReviewConfirmBookingScreenState();
}

class _ReviewConfirmBookingScreenState
    extends State<ReviewConfirmBookingScreen> {
  String? _patientName;
  String? _date;
  late int _availableSlots;
  bool _isLoading = false;
  bool _isConfirmed = false;
  bool _isLoadingData = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _availableSlots = widget.availableSlots;
    _loadData();
  }

  String get _tokenNumber => 'T-${_availableSlots.toString().padLeft(3, '0')}';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return DateUtils.dateOnly(value.toDate());
    if (value is DateTime) return DateUtils.dateOnly(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return DateUtils.dateOnly(parsed);
    }
    return null;
  }

  String _dateLabel(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (mounted) {
          setState(() {
            final selectedName = widget.bookingForName.trim();
            _patientName = selectedName.isEmpty ? 'Patient' : selectedName;
          });
        }
      } else {
        throw StateError('Please sign in before booking an appointment.');
      }

      final sessionDoc = await FirebaseFirestore.instance
          .collection('sessions')
          .doc(widget.sessionId)
          .get();
      if (sessionDoc.exists) {
        final data = sessionDoc.data()!;
        final appointmentDate = _readDate(data['date']);
        final available = (data['availableSlots'] as num?)?.toInt();
        if (mounted) {
          setState(() {
            _date = appointmentDate == null
                ? 'N/A'
                : _dateLabel(appointmentDate);
            _availableSlots = available ?? widget.availableSlots;
          });
        }
      } else {
        throw StateError('Session does not exist.');
      }
    } catch (error) {
      debugPrint('ERROR loading booking data: $error');
      if (mounted) {
        setState(() {
          _loadError = 'Unable to load booking details: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _confirmBooking() async {
    debugPrint('========================================');
    debugPrint('DEBUG: === BOOKING STARTED ===');
    debugPrint('========================================');

    if (!_isConfirmed) {
      debugPrint('ERROR: Checkbox not checked');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the guidelines'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_availableSlots <= 0) {
      debugPrint('ERROR: No slots available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session is fully booked'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in before booking an appointment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final parsedDate = _date == null ? null : _readDate(_date);
    if (parsedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The appointment date is unavailable. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final sessionRef = firestore.collection('sessions').doc(widget.sessionId);
      final appointmentRef = firestore.collection('appointments').doc();
      final referenceNumber = 'OPD-${DateTime.now().millisecondsSinceEpoch}';

      final bookingResult = await firestore
          .runTransaction<({String patientName, String tokenNumber})>((
            transaction,
          ) async {
            debugPrint('DEBUG: Transaction START');
            final sessionDoc = await transaction.get(sessionRef);

            if (!sessionDoc.exists) {
              throw StateError('Session does not exist');
            }

            final sessionData = sessionDoc.data()!;
            final rawSlots = sessionData['availableSlots'];
            final currentSlots = rawSlots is num ? rawSlots.toInt() : 0;
            debugPrint('DEBUG: Current slots = $currentSlots');
            if (currentSlots <= 0) {
              throw StateError('Session is fully booked');
            }

            final patientName = widget.bookingForName.trim();
            if (patientName.isEmpty) {
              throw StateError('The selected patient name is unavailable.');
            }
            final currentBookedCount =
                (sessionData['bookedCount'] as num?)?.toInt() ??
                (((sessionData['totalSlots'] as num?)?.toInt() ??
                            currentSlots) -
                        currentSlots)
                    .clamp(0, 999);
            final tokenNumber = 'T-${currentSlots.toString().padLeft(3, '0')}';
            final newSlots = currentSlots - 1;

            debugPrint('DEBUG: Token = $tokenNumber');
            debugPrint('DEBUG: Reference = $referenceNumber');
            transaction.update(sessionRef, {
              'availableSlots': newSlots,
              'bookedCount': currentBookedCount + 1,
              'status': newSlots == 0 ? 'full' : 'available',
              'isAvailable': newSlots > 0,
            });
            debugPrint('DEBUG: Slots decremented to $newSlots');
            debugPrint('DEBUG: Appointment ID = ${appointmentRef.id}');
            transaction.set(appointmentRef, {
              'patientId': user.uid,
              'patientName': patientName,
              'sessionId': widget.sessionId,
              'doctorId': sessionData['doctorId'],
              'doctorName': sessionData['doctorName'],
              'hospitalId': sessionData['hospitalId'],
              'hospitalName': sessionData['hospitalName'],
              'department': sessionData['department'],
              'appointmentDate': Timestamp.fromDate(parsedDate),
              'appointmentTime': widget.time,
              'tokenNumber': tokenNumber,
              'status': 'confirmed',
              'referenceNumber': referenceNumber,
              'createdAt': FieldValue.serverTimestamp(),
            });
            debugPrint('DEBUG: Appointment set');

            return (patientName: patientName, tokenNumber: tokenNumber);
          });

      debugPrint('DEBUG: Transaction COMMITTED');
      debugPrint('DEBUG: Token = ${bookingResult.tokenNumber}');
      debugPrint('DEBUG: Reference = $referenceNumber');

      if (!mounted) return;
      setState(() => _isLoading = false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => BookingConfirmedScreen(
            patientName: bookingResult.patientName,
            date: _date ?? '',
            time: widget.time,
            tokenNumber: bookingResult.tokenNumber,
            referenceNumber: referenceNumber,
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('BOOKING ERROR: $error');
      debugPrint('Stack: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Booking Failed'),
            content: Text(error.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _discardBooking() async {
    final discard = await showDialog<bool>(
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
    if (discard == true && mounted) Navigator.pop(context);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm Booking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_loadError!, textAlign: TextAlign.center),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _detailRow('Patient Name', _patientName ?? 'Patient'),
                          const Divider(),
                          _detailRow('Date', _date ?? 'N/A'),
                          const Divider(),
                          _detailRow('Time', widget.time),
                          const Divider(),
                          _detailRow('Token Number', _tokenNumber),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: CheckboxListTile(
                      value: _isConfirmed,
                      onChanged: _isLoading
                          ? null
                          : (value) =>
                                setState(() => _isConfirmed = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'I agree to the National Hospital OPD guidelines and consent to receive digital queue token updates.',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm & Get Token'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _discardBooking,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Discard Booking'),
                  ),
                ],
              ),
            ),
    );
  }
}
