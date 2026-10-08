import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'review_confirm_booking.dart';

class SelectAppointmentSlotScreen extends StatefulWidget {
  const SelectAppointmentSlotScreen({super.key});

  @override
  State<SelectAppointmentSlotScreen> createState() => _SelectAppointmentSlotScreenState();
}

class _SelectAppointmentSlotScreenState extends State<SelectAppointmentSlotScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  
  int _extractHour(String time) {
    final parts = time.trim().split(' ');
    if (parts.length < 2) return 0;
    final timePart = parts[0];
    final period = parts[1].toUpperCase();
    final hourStr = timePart.split(':')[0];
    int hour = int.tryParse(hourStr) ?? 0;

    if (period == 'PM' && hour != 12) {
      hour += 12;
    } else if (period == 'AM' && hour == 12) {
      hour = 0;
    }
    return hour;
  }

  int _compareTime(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
    final timeA = (a.data() as Map<String, dynamic>)['time'] ?? '';
    final timeB = (b.data() as Map<String, dynamic>)['time'] ?? '';
    return _extractHour(timeA).compareTo(_extractHour(timeB));
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(String sessionId, Map<String, dynamic> session) {
    final availableSlots = session['availableSlots'] ?? 0;
    final time = session['time'] ?? 'N/A';
    final hasSlots = availableSlots > 0;

    Color badgeColor;
    String badgeText;

    if (availableSlots == 0) {
      badgeColor = Colors.red.shade100;
      badgeText = 'Fully Booked';
    } else if (availableSlots <= 2) {
      badgeColor = Colors.orange.shade100;
      badgeText = '$availableSlots Slots left';
    } else {
      badgeColor = Colors.green.shade100;
      badgeText = '$availableSlots Slots left';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.blue, size: 24),
                const SizedBox(width: 12),
                Text(
                  time,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasSlots ? () => _navigateToBooking(sessionId, session) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasSlots ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(hasSlots ? 'Book Now' : 'Full'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToBooking(String sessionId, Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewConfirmBookingScreen(
          sessionId: sessionId,
          doctorId: session['doctorId'] ?? '',
          time: session['time'] ?? '',
          date: DateFormat('yyyy-MM-dd').format(_selectedDay),
          availableSlots: session['availableSlots'] ?? 0,
        ),
      ),
    ).then((_) => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          title: const Text('Select Appointment Slot'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now(), // Disable past dates
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const Divider(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('sessions')
                    .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(_selectedDay))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final allSessions = snapshot.data?.docs ?? [];

                  if (allSessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.event_busy, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('No sessions available'),
                          Text('Please try again later', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final morning = <QueryDocumentSnapshot>[];
                  final afternoon = <QueryDocumentSnapshot>[];
                  final evening = <QueryDocumentSnapshot>[];

                  final Map<String, QueryDocumentSnapshot> uniqueSessions = {};
                  for (var doc in allSessions) {
                    final time = (doc.data() as Map<String, dynamic>)['time'] ?? '';
                    if (!uniqueSessions.containsKey(time)) {
                       uniqueSessions[time] = doc;
                    }
                  }

                  for (var doc in uniqueSessions.values) {
                    final time = (doc.data() as Map<String, dynamic>)['time'] ?? '';
                    final hour = _extractHour(time);

                    if (hour < 12) {
                      morning.add(doc);
                    } else if (hour < 15) {
                      afternoon.add(doc);
                    } else {
                      evening.add(doc);
                    }
                  }

                  morning.sort((a, b) => _compareTime(a, b));
                  afternoon.sort((a, b) => _compareTime(a, b));
                  evening.sort((a, b) => _compareTime(a, b));

                  final displaySessions = <QueryDocumentSnapshot>[];
                  if (morning.isNotEmpty) displaySessions.add(morning.first);
                  if (afternoon.isNotEmpty) displaySessions.add(afternoon.first);
                  if (evening.isNotEmpty) displaySessions.add(evening.first);

                  if (displaySessions.isEmpty) {
                     return const Center(child: Text('No sessions available for this date'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displaySessions.length,
                    itemBuilder: (context, index) {
                      final doc = displaySessions[index];
                      final sessionTime = (doc.data() as Map<String, dynamic>)['time'] ?? '';
                      final hour = _extractHour(sessionTime);
                      
                      String title = 'Evening Session';
                      IconData icon = Icons.nightlight_round;
                      Color color = Colors.indigo;
                      
                      if (hour < 12) {
                        title = 'Morning Session';
                        icon = Icons.wb_sunny;
                        color = Colors.orange;
                      } else if (hour < 15) {
                        title = 'Afternoon Session';
                        icon = Icons.wb_twilight;
                        color = Colors.deepPurple;
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCategoryHeader(title, icon, color),
                          _buildSessionCard(doc.id, doc.data() as Map<String, dynamic>),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
