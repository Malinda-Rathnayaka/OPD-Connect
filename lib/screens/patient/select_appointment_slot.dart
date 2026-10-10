import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'review_confirm_booking.dart';

class SelectAppointmentSlotScreen extends StatefulWidget {
  final String bookingForId;
  final String bookingForName;

  const SelectAppointmentSlotScreen({
    super.key,
    required this.bookingForId,
    required this.bookingForName,
  });

  @override
  State<SelectAppointmentSlotScreen> createState() =>
      _SelectAppointmentSlotScreenState();
}

class _SelectAppointmentSlotScreenState
    extends State<SelectAppointmentSlotScreen> {
  DateTime? _selectedDay;
  String? _selectedSessionId;

  DateTime? _sessionDate(Map<String, dynamic> session) {
    final value = session['date'];
    if (value is Timestamp) return DateUtils.dateOnly(value.toDate());
    if (value is DateTime) return DateUtils.dateOnly(value);
    if (value is! String || value.trim().isEmpty) return null;

    final text = value.trim();
    for (final format in [
      DateFormat('yyyy-MM-dd'),
      DateFormat('EEE, d MMM yyyy', 'en_US'),
      DateFormat('EEE, d MMM', 'en_US'),
    ]) {
      try {
        final parsed = format.parseStrict(text);
        return DateUtils.dateOnly(parsed);
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  Widget _buildSessionCard(String sessionId, Map<String, dynamic> session) {
    final availableSlots = (session['availableSlots'] as num?)?.toInt() ?? 0;
    final hasSlots = availableSlots > 0;
    final isSelected = _selectedSessionId == sessionId;
    final sessionType = session['sessionType']?.toString() ?? 'OPD';
    final startTime = session['startTime']?.toString() ?? '';
    final endTime = session['endTime']?.toString() ?? '';
    final badgeColor = !hasSlots
        ? Colors.red.shade100
        : availableSlots <= 2
        ? Colors.orange.shade100
        : Colors.green.shade100;
    final badgeText = hasSlots ? '$availableSlots Slots left' : 'Fully Booked';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: hasSlots
            ? () => setState(() => _selectedSessionId = sessionId)
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: hasSlots
                    ? (isSelected ? Colors.blue : Colors.grey)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 12),
              Icon(
                sessionType == 'Morning'
                    ? Icons.wb_sunny
                    : sessionType == 'Afternoon'
                    ? Icons.wb_twilight
                    : Icons.nightlight_round,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionType,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$startTime - $endTime'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToBooking(
    String sessionId,
    DateTime selectedDate,
    String time,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewConfirmBookingScreen(
          sessionId: sessionId,
          time: time,
          appointmentDate: selectedDate,
          bookingForId: widget.bookingForId,
          bookingForName: widget.bookingForName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final firstFutureDay = today.add(const Duration(days: 1));

    return Theme(
      data: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Appointment Slot'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('sessions')
              .where('scheduleScope', isEqualTo: 'hospital')
              .where('hospitalId', isEqualTo: 'colombo-national')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Unable to load sessions: ${snapshot.error}'),
              );
            }

            final sessionDocs = snapshot.data?.docs ?? [];
            final sessionsByDate =
                <
                  DateTime,
                  Map<String, QueryDocumentSnapshot<Map<String, dynamic>>>
                >{};
            for (final doc in sessionDocs) {
              final data = doc.data();
              final sessionDate = _sessionDate(data);
              if (sessionDate == null || !sessionDate.isAfter(today)) continue;
              final sessionTypeKey = data['sessionTypeKey']?.toString();
              if (sessionTypeKey == null ||
                  !const {
                    'morning',
                    'afternoon',
                    'evening',
                  }.contains(sessionTypeKey)) {
                continue;
              }
              sessionsByDate
                  .putIfAbsent(sessionDate, () => {})
                  .putIfAbsent(sessionTypeKey, () => doc);
            }

            final availableDates = sessionsByDate.keys.toList()..sort();
            final selectedDate =
                _selectedDay != null &&
                    sessionsByDate.containsKey(
                      DateUtils.dateOnly(_selectedDay!),
                    )
                ? DateUtils.dateOnly(_selectedDay!)
                : availableDates.isNotEmpty
                ? availableDates.first
                : firstFutureDay;
            final sessionsForDate =
                sessionsByDate[selectedDate]?.values.toList() ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            const sessionOrder = {'morning': 0, 'afternoon': 1, 'evening': 2};
            sessionsForDate.sort((a, b) {
              final typeA = a.data()['sessionTypeKey']?.toString() ?? '';
              final typeB = b.data()['sessionTypeKey']?.toString() ?? '';
              return sessionOrder[typeA]!.compareTo(sessionOrder[typeB]!);
            });
            QueryDocumentSnapshot<Map<String, dynamic>>? selectedSession;
            for (final doc in sessionsForDate) {
              if (doc.id == _selectedSessionId) {
                selectedSession = doc;
                break;
              }
            }
            final selectedSlots =
                (selectedSession?.data()['availableSlots'] as num?)?.toInt() ??
                0;
            final selectedSessionId = selectedSession?.id;
            final selectedTime =
                selectedSession?.data()['time']?.toString() ??
                '${selectedSession?.data()['startTime'] ?? ''} - ${selectedSession?.data()['endTime'] ?? ''}';

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: TableCalendar<void>(
                    firstDay: firstFutureDay,
                    lastDay: DateUtils.dateOnly(
                      today.add(const Duration(days: 365)),
                    ),
                    focusedDay: selectedDate,
                    selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                    enabledDayPredicate: (day) =>
                        DateUtils.dateOnly(day).isAfter(today) &&
                        sessionsByDate.containsKey(DateUtils.dateOnly(day)),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = DateUtils.dateOnly(selected);
                        _selectedSessionId = null;
                      });
                    },
                    calendarFormat: CalendarFormat.month,
                    headerStyle: const HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose one OPD session for ${DateFormat('EEE, d MMM yyyy').format(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (sessionDocs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No sessions available'),
                        Text(
                          'Please try again later',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else if (sessionsForDate.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No sessions are available on this date.'),
                    ),
                  )
                else
                  ...sessionsForDate.map(
                    (doc) => _buildSessionCard(doc.id, doc.data()),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedSessionId != null && selectedSlots > 0
                        ? () => _navigateToBooking(
                            selectedSessionId,
                            selectedDate,
                            selectedTime,
                          )
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('Book Selected Session'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
