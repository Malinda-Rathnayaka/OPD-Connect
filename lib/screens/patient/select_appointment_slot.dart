import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
  static const List<Map<String, String>> weekDates = [
    {'day': 'Mon', 'date': '22', 'fullDate': 'Mon, 22 Sep'},
    {'day': 'Tue', 'date': '23', 'fullDate': 'Tue, 23 Sep'},
    {'day': 'Wed', 'date': '24', 'fullDate': 'Wed, 24 Sep'},
    {'day': 'Thu', 'date': '25', 'fullDate': 'Thu, 25 Sep'},
    {'day': 'Fri', 'date': '26', 'fullDate': 'Fri, 26 Sep'},
    {'day': 'Sat', 'date': '27', 'fullDate': 'Sat, 27 Sep'},
    {'day': 'Sun', 'date': '28', 'fullDate': 'Sun, 28 Sep'},
  ];

  int _selectedDateIndex = 0;
  bool _morningSessionSelected = true;

  String get _selectedFullDate => weekDates[_selectedDateIndex]['fullDate'] ?? 'Mon, 22 Sep';
  String get _selectedSessionType => _morningSessionSelected ? 'Morning' : 'Evening';

  Query<Map<String, dynamic>> get _sessionsQuery {
    print('DEBUG QUERY: doctorId = ${widget.doctorId}');
    print('DEBUG QUERY: hospitalId = ${widget.hospitalId}');
    print('DEBUG QUERY: date = $_selectedFullDate');
    print('DEBUG QUERY: sessionType = $_selectedSessionType');

    return FirebaseFirestore.instance
        .collection('sessions')
        .where('doctorId', isEqualTo: widget.doctorId)
        .where('hospitalId', isEqualTo: widget.hospitalId)
        .where('date', isEqualTo: _selectedFullDate)
        .where('sessionType', isEqualTo: _selectedSessionType);
  }

  DateTime _parseDateString(String value) {
    final parts = value.split(', ');
    if (parts.length < 2) {
      return DateTime.now();
    }

    final dayString = parts[1].split(' ').first;
    final monthString = parts[1].split(' ').last;

    const monthMap = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final day = int.tryParse(dayString) ?? 22;
    final month = monthMap[monthString] ?? 9;
    final year = DateTime.now().year;

    return DateTime(year, month, day);
  }

  Color _badgeColorForSession(Map<String, dynamic> session) {
    final availableSlots = (session['availableSlots'] as num?)?.toInt() ?? 0;
    final isAvailable = (session['isAvailable'] as bool?) ?? true;

    if (availableSlots == 0 || isAvailable == false) {
      return Colors.red.shade100;
    }
    if (availableSlots <= 5) {
      return Colors.orange.shade100;
    }
    return Colors.green.shade100;
  }

  Color _badgeTextColorForSession(Map<String, dynamic> session) {
    final availableSlots = (session['availableSlots'] as num?)?.toInt() ?? 0;
    final isAvailable = (session['isAvailable'] as bool?) ?? true;

    if (availableSlots == 0 || isAvailable == false) {
      return Colors.red.shade800;
    }
    if (availableSlots <= 5) {
      return Colors.orange.shade800;
    }
    return Colors.green.shade800;
  }

  String _badgeTextForSession(Map<String, dynamic> session) {
    final availableSlots = (session['availableSlots'] as num?)?.toInt() ?? 0;
    final isAvailable = (session['isAvailable'] as bool?) ?? true;

    if (availableSlots == 0 || isAvailable == false) {
      return 'Fully Booked';
    }
    return '$availableSlots Slots left';
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
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _sessionsQuery.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Error loading sessions'));
            }

            final allDocs = snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
            final sessions = allDocs.where((doc) {
              final data = doc.data();
              final matchesDate = (data['date'] as String?) == _selectedFullDate;
              final matchesType = (data['sessionType'] as String?) == _selectedSessionType;
              return matchesDate && matchesType;
            }).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: weekDates.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedDateIndex;
                        final item = weekDates[index];
                        final day = item['day'] ?? 'Mon';
                        final date = item['date'] ?? '22';

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
                                  day,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
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
                    'Available sessions for $_selectedFullDate',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (sessions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'No sessions available for $_selectedFullDate',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    )
                  else
                    ...sessions.map((doc) {
                      final session = doc.data();
                      final String sessionDate = (session['date'] as String?) ?? _selectedFullDate;
                      final String startTime = (session['startTime'] as String?) ?? '09:00 AM';
                      final String endTime = (session['endTime'] as String?) ?? '12:00 PM';
                      final int availableSlots = (session['availableSlots'] as num?)?.toInt() ?? 0;
                      final bool isAvailable = (session['isAvailable'] as bool?) ?? true;
                      final bool isFull = availableSlots <= 0 || isAvailable == false;

                      final badgeText = _badgeTextForSession(session);
                      final badgeColor = _badgeColorForSession(session);
                      final badgeTextColor = _badgeTextColorForSession(session);
                      final buttonText = isFull ? 'Full' : 'Book';
                      final buttonColor = isFull ? Colors.grey : Colors.blue;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: isFull ? 0.7 : 1,
                          child: Card(
                            color: isFull ? Colors.grey.shade100 : Colors.white,
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
                                        sessionDate,
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
                                        '$startTime - $endTime',
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
                                      onPressed: isFull
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
                                                    sessionId: doc.id,
                                                    date: _parseDateString(sessionDate),
                                                    time: startTime,
                                                    slotNumber: availableSlots,
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
            );
          },
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
