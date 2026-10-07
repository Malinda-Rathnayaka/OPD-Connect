import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'department_select.dart';
import 'patient_home_screen.dart';
import 'doctor_availability.dart';
import 'my_family_profile.dart';
import 'review_confirm_booking.dart';

class SelectAppointmentSlotScreen extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String hospitalId;
  final String hospitalName;
  final String department;

  const SelectAppointmentSlotScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.hospitalId,
    required this.hospitalName,
    required this.department,
  });

  @override
  State<SelectAppointmentSlotScreen> createState() => _SelectAppointmentSlotScreenState();
}

class _SelectAppointmentSlotScreenState extends State<SelectAppointmentSlotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _selectedDateIndex = 0;
  bool _morningSessionSelected = true;
  bool _isLoading = true;
  List<_SessionCardData> _sessions = [];

  DateTime get _selectedDate {
    final monday = _weekDates.first;
    return monday.add(Duration(days: _selectedDateIndex));
  }

  List<DateTime> get _weekDates {
    final now = DateTime.now();
    final currentDate = DateTime(now.year, now.month, now.day);
    final monday = currentDate.subtract(Duration(days: currentDate.weekday - 1));
    return List.generate(7, (index) => monday.add(Duration(days: index)));
  }

  List<String> get _dateLabels {
    return _weekDates.map((date) => '${_formatDayShort(date)}\n${date.day}').toList();
  }

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      final generatedSessions = <_SessionCardData>[];

      for (final date in _weekDates) {
        for (final sessionType in ['Morning', 'Evening']) {
          final sessionStart = sessionType == 'Morning'
              ? DateTime(date.year, date.month, date.day, 9, 0)
              : DateTime(date.year, date.month, date.day, 15, 0);

          final sessionEnd = sessionType == 'Morning'
              ? DateTime(date.year, date.month, date.day, 12, 0)
              : DateTime(date.year, date.month, date.day, 18, 0);

          final totalSlots = 12;
          final availableSlots = (date.weekday == DateTime.now().weekday && sessionType == 'Morning')
              ? 12
              : (date.weekday == DateTime.now().weekday + 1 && sessionType == 'Morning')
                  ? 3
                  : 0;

          generatedSessions.add(
            _SessionCardData(
              date: date,
              label: _formatDateForDisplay(date),
              startTime: Timestamp.fromDate(sessionStart),
              endTime: Timestamp.fromDate(sessionEnd),
              availableSlots: availableSlots,
              totalSlots: totalSlots,
              sessionType: sessionType,
            ),
          );
        }
      }

      final snapshot = await _firestore.collection('sessions').get();
      if (snapshot.docs.isNotEmpty) {
        final sessionData = snapshot.docs.map((doc) {
          final data = doc.data();
          return _SessionCardData(
            date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
            label: (data['dateLabel'] as String?) ?? 'Session',
            startTime: data['startTime'] as Timestamp? ?? Timestamp.now(),
            endTime: data['endTime'] as Timestamp? ?? Timestamp.now(),
            availableSlots: (data['availableSlots'] as num?)?.toInt() ?? 0,
            totalSlots: (data['totalSlots'] as num?)?.toInt() ?? 0,
            sessionType: (data['sessionType'] as String?) ?? 'Morning',
          );
        }).toList();

        if (sessionData.isNotEmpty) {
          generatedSessions.clear();
          generatedSessions.addAll(sessionData);
        }
      }

      if (mounted) {
        setState(() {
          _sessions = generatedSessions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _sessions = [];
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateForDisplay(DateTime date) {
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = weekdayNames[date.weekday - 1];
    final dayNumber = date.day.toString();
    return '$dayName, $dayNumber';
  }

  String _formatDayShort(DateTime date) {
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdayNames[date.weekday - 1];
  }

  String _formatTimeRange(Timestamp start, Timestamp end) {
    final startDate = start.toDate();
    final endDate = end.toDate();
    final startText = _formatTime(startDate);
    final endText = _formatTime(endDate);
    return '$startText - $endText';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final minute = date.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    final minuteText = minute.toString().padLeft(2, '0');
    return '${hour12.toString().padLeft(2, '0')}:$minuteText $period';
  }

  List<_SessionCardData> get _filteredSessions {
    final selectedDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final selectedType = _morningSessionSelected ? 'Morning' : 'Evening';
    return _sessions
        .where((session) {
          final sessionDate = DateTime(
            session.date.year,
            session.date.month,
            session.date.day,
          );
          return sessionDate == selectedDate && session.sessionType == selectedType;
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDate;
    final selectedDayLabel = _formatDateForDisplay(selectedDate);

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
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 78,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _dateLabels.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final isSelected = index == _selectedDateIndex;
                          final dayParts = _dateLabels[index].split('\n');

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedDateIndex = index;
                              });
                            },
                            child: Container(
                              width: 72,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blue : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey.shade300,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayParts[0],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dayParts[1],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black87,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _SessionToggleButton(
                            label: 'Morning Session',
                            selected: _morningSessionSelected,
                            onTap: () {
                              setState(() {
                                _morningSessionSelected = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SessionToggleButton(
                            label: 'Evening Session',
                            selected: !_morningSessionSelected,
                            onTap: () {
                              setState(() {
                                _morningSessionSelected = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Available sessions for $selectedDayLabel',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_filteredSessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Text(
                          'No sessions available for this date',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      )
                    else
                      ..._filteredSessions.map((session) {
                        final sessionDate = session.date;
                        final isFullyBooked = session.availableSlots <= 0;
                        final isLowAvailability = session.availableSlots > 0 && session.availableSlots <= 3;
                        final badgeText = isFullyBooked
                            ? 'Fully Booked'
                            : '${session.availableSlots} Slots left';
                        final badgeColor = isFullyBooked
                            ? Colors.red.shade100
                            : isLowAvailability
                                ? Colors.orange.shade100
                                : Colors.green.shade100;
                        final badgeTextColor = isFullyBooked
                            ? Colors.red.shade800
                            : isLowAvailability
                                ? Colors.orange.shade800
                                : Colors.green.shade800;
                        final buttonText = isFullyBooked ? 'Full' : 'Book';
                        final buttonColor = isFullyBooked ? Colors.grey : Colors.blue;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Opacity(
                            opacity: isFullyBooked ? 0.7 : 1,
                            child: Card(
                              color: isFullyBooked ? Colors.grey.shade100 : Colors.white,
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
                                        Text(
                                          _formatDateForDisplay(sessionDate),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
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
                                            style: TextStyle(
                                              color: badgeTextColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          size: 18,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatTimeRange(session.startTime, session.endTime),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isFullyBooked
                                            ? null
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => ReviewConfirmBookingScreen(
                                                      hospitalId: widget.hospitalId,
                                                      hospitalName: widget.hospitalName,
                                                      doctorId: widget.doctorId,
                                                      doctorName: widget.doctorName,
                                                      department: widget.department,
                                                      date: sessionDate,
                                                      time: _formatTimeRange(
                                                        session.startTime,
                                                        session.endTime,
                                                      ),
                                                      slotNumber: session.availableSlots > 0
                                                          ? session.availableSlots
                                                          : 0,
                                                    ),
                                                  ),
                                                );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: buttonColor,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: Colors.grey,
                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(buttonText),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
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
      ),
    );
  }
}

class _SessionToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SessionToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? Colors.blue : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.blue,
          side: BorderSide(color: selected ? Colors.blue : Colors.blue.shade200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _SessionCardData {
  final DateTime date;
  final String label;
  final Timestamp startTime;
  final Timestamp endTime;
  final int availableSlots;
  final int totalSlots;
  final String sessionType;

  const _SessionCardData({
    required this.date,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.availableSlots,
    required this.totalSlots,
    required this.sessionType,
  });
}
